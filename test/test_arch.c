/* =====================================================
   test_arch.c
   八、底層架構（透過可觀察行為間接驗證）

   1. 字串常數池去重（stringLiterals）
      → 同一字串多次使用，IR 只定義一次 @.str.N
   2. IR Buffer Stack（pushBuffer / popBuffer）
      → if/while/for body 的 IR 正確延遲輸出
   3. Terminator Guard（lastInstrIsTerminator）
      → 多重 return / break / continue 後不插入多餘 br
   4. charPtrTemps 指標退化追蹤
      → char 陣列正確傳給 printf("%s") 不產生多餘 load
   5. 十六進位浮點數精準轉換
      → float 常數以 hex 形式儲存，讀回結果精準
   6. ReturnTypeStack
      → 巢狀函式、不同回傳型別的函式，return 型別正確
   ===================================================== */

/* ──────────────────────────────────────
   6. ReturnTypeStack：不同回傳型別的巢狀呼叫
   ────────────────────────────────────── */
int    ret_int(int x)   { return x * 2; }
float  ret_float(float x) { return x + 0.5; }
double ret_double(double x) { return x * x; }
void   ret_void(int x)  { printf("void got %d\n", x); return; }

int outer(int n) {
    float f;
    f = ret_float(n);
    return ret_int((int)f);
}

float nested_float(int a, int b) {
    int s;
    s = ret_int(a) + ret_int(b);
    return ret_float(s);
}

/* ──────────────────────────────────────
   3. Terminator Guard：早期 return
   ────────────────────────────────────── */
int early_return(int x) {
    if (x < 0) return -1;
    if (x == 0) return 0;
    return 1;
}

int multi_branch(int x) {
    if (x > 100) {
        return 3;
    } else if (x > 50) {
        return 2;
    } else if (x > 0) {
        return 1;
    } else {
        return 0;
    }
}

/* ──────────────────────────────────────
   3. Terminator Guard：break / continue
   ────────────────────────────────────── */
int sum_with_break(int limit) {
    int s;
    int i;
    s = 0;
    i = 0;
    while (1) {
        if (i >= limit) break;
        s = s + i;
        i = i + 1;
    }
    return s;
}

int sum_skip_even(int n) {
    int s;
    int i;
    s = 0;
    i = 0;
    while (i < n) {
        i = i + 1;
        if (i % 2 == 0) continue;
        s = s + i;
    }
    return s;
}

/* ──────────────────────────────────────
   4. charPtrTemps：char 陣列傳給函式
   ────────────────────────────────────── */
int my_strlen(char s[], int max) {
    int i;
    i = 0;
    while (i < max && s[i] != 0) {
        i = i + 1;
    }
    return i;
}

void print_upper_count(char s[], int n) {
    int count;
    int i;
    count = 0;
    i = 0;
    while (i < n) {
        if (s[i] >= 65 && s[i] <= 90) count = count + 1;
        i = i + 1;
    }
    printf("upper=%d\n", count);
}

int main(void) {

    /* ---------------------------------------------------
       1. 字串常數池去重
          同一字串字面值在 IR 中只出現一次 @.str.N
          透過多次使用相同字串仍輸出正確來驗證
       --------------------------------------------------- */
    printf("--- 1. String pool dedup ---\n");

    printf("hello\n");
    printf("hello\n");
    printf("hello\n");

    char s1[32];
    char s2[32];
    char s3[32];
    s1 = "world";
    s2 = "world";
    s3 = "world";
    printf("%s %s %s\n", s1, s2, s3);

    printf("test\n");
    int dup_check;
    dup_check = 1;
    if (dup_check) printf("test\n");
    while (0) printf("test\n");

    char buf[64];
    sprintf(buf, "fmt=%d", 42);
    printf("%s\n", buf);
    sprintf(buf, "fmt=%d", 99);
    printf("%s\n", buf);

    /* ---------------------------------------------------
       2. IR Buffer Stack
          if / while / for 的 body 必須在條件跳轉後輸出
          以複雜巢狀控制流驗證 IR 順序正確
       --------------------------------------------------- */
    printf("--- 2. IR Buffer Stack ---\n");

    int v;
    v = 5;
    if (v > 3) {
        printf("branch A\n");
        if (v > 4) {
            printf("branch A1\n");
        } else {
            printf("branch A2\n");
        }
    } else {
        printf("branch B\n");
    }

    int cnt;
    cnt = 0;
    while (cnt < 3) {
        if (cnt == 1) {
            printf("cnt==1\n");
        }
        cnt = cnt + 1;
    }

    int fsum;
    fsum = 0;
    for (int k = 0; k < 4; k++) {
        fsum = fsum + k;
    }
    printf("fsum=%d\n", fsum);

    /* ---------------------------------------------------
       3. Terminator Guard
          early return / multi-branch / break / continue
       --------------------------------------------------- */
    printf("--- 3. Terminator Guard ---\n");

    printf("early_return(-5) = %d\n", early_return(-5));
    printf("early_return(0) = %d\n",  early_return(0));
    printf("early_return(7) = %d\n",  early_return(7));

    printf("multi_branch(200) = %d\n", multi_branch(200));
    printf("multi_branch(75) = %d\n",  multi_branch(75));
    printf("multi_branch(25) = %d\n",  multi_branch(25));
    printf("multi_branch(-1) = %d\n",  multi_branch(-1));

    printf("sum_with_break(5) = %d\n", sum_with_break(5));
    printf("sum_skip_even(6) = %d\n",  sum_skip_even(6));

    /* ---------------------------------------------------
       4. charPtrTemps 指標退化追蹤
          char 陣列傳給 strlen/printf/自訂函式
       --------------------------------------------------- */
    printf("--- 4. charPtrTemps ---\n");

    char msg[32];
    msg = "Hello LLVM";
    printf("%s\n", msg);
    printf("strlen=%d\n", strlen(msg));
    printf("my_strlen=%d\n", my_strlen(msg, 32));
    print_upper_count(msg, 10);

    char alpha[8];
    alpha = "ABCdef";
    print_upper_count(alpha, 6);

    /* ---------------------------------------------------
       5. 十六進位浮點數精準轉換
          float 常數透過 hex 存入 IR，讀回後精準
       --------------------------------------------------- */
    printf("--- 5. Hex float precision ---\n");

    float f1;
    float f2;
    float f3;
    float f4;
    float f5;
    f1 = 0.1;
    f2 = 0.2;
    f3 = 0.1 + 0.2;
    printf("0.1 = %f\n", f1);
    printf("0.2 = %f\n", f2);
    printf("0.1+0.2 = %f\n", f3);

    f4 = 3.14159265;
    printf("3.14159265 = %f\n", f4);

    f5 = 1.0 / 3.0;
    printf("1/3 = %f\n", f5);

    float small;
    small = 0.000001;
    printf("0.000001 = %f\n", small);

    float big;
    big = 1234567.89;
    printf("1234567.89 = %f\n", big);

    if (f1 + f2 > 0.29) printf("0.1+0.2 > 0.29 OK\n");
    if (f4 > 3.14)      printf("pi > 3.14 OK\n");

    /* ---------------------------------------------------
       6. ReturnTypeStack
          巢狀函式呼叫、不同回傳型別
       --------------------------------------------------- */
    printf("--- 6. ReturnTypeStack ---\n");

    printf("ret_int(5) = %d\n",     ret_int(5));
    printf("ret_float(2.5) = %f\n", ret_float(2.5));
    printf("ret_double(3.0) = %f\n", ret_double(3.0));
    ret_void(42);

    printf("outer(3) = %d\n",           outer(3));
    printf("nested_float(2,3) = %f\n",  nested_float(2, 3));

    int ri;
    ri = ret_int(ret_int(3));
    printf("ret_int(ret_int(3)) = %d\n", ri);

    float rf;
    rf = ret_float(ret_float(1.0));
    printf("ret_float(ret_float(1.0)) = %f\n", rf);

    return 0;
}
