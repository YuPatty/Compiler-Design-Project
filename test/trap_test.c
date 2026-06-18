/* ================================================================
   TRAP TEST — 助教等級深度邊界測試
   涵蓋所有基本 80 分功能的常見學生錯誤陷阱

   執行方式（stdin 需要輸入）：
     printf "42\n-7\n3.14\n-2.5\n2.0\n3.0\n5\n-3\n10\n20\n1.5\n" | ./a.out

   共 15 大類陷阱，103 個測試點
   ================================================================ */

int main() {

    /* ============================================================
       TRAP-1: 整數除法截斷方向（朝零，不是 floor）
       學生常犯：-7/2=-4（錯），正確答案是 -7/2=-3
       ============================================================ */
    printf("%d\n", 7/2);        /* 3  */
    printf("%d\n", -7/2);       /* -3  NOT neg4 */
    printf("%d\n", 7/-2);       /* -3 */
    printf("%d\n", -7/-2);      /* 3  */
    printf("%d\n", 1/2);        /* 0  */
    printf("%d\n", -1/2);       /* 0  NOT neg1 */
    printf("%d\n", 3/4);        /* 0  */
    printf("%d\n", -3/4);       /* 0  NOT neg1 */

    /* ============================================================
       TRAP-2: 運算子優先順序與左結合律
       學生常犯：忘記 100/10/2 = (100/10)/2 = 5，而非 100/(10/2) = 20
       ============================================================ */
    printf("%d\n", 2+3*4);       /* 14  NOT t20 */
    printf("%d\n", 10-2*3+1);    /* 5   NOT neg7 */
    printf("%d\n", 100/10/2);    /* 5   left-to-right */
    printf("%d\n", 8-3-2);       /* 3   left-to-right */
    printf("%d\n", 2*3+4*5-1);   /* 25 */
    printf("%d\n", (2+3)*4);     /* 20 */
    printf("%d\n", 10-(3-2));    /* 9  */
    printf("%d\n", 2+3*0);       /* 2  */

    /* ============================================================
       TRAP-3: 一元負號各種情境
       學生常犯：-a*-a 解析錯誤，或 -(a+b) 產生錯 IR
       ============================================================ */
    int a;
    a = 5;
    printf("%d\n", -a);          /* -5 */
    printf("%d\n", -a+10);       /* 5  */
    printf("%d\n", a+-3);        /* 2  */
    printf("%d\n", -a*-a);       /* 25 */
    int b;
    b = 4;
    printf("%d\n", -(a+b));      /* -9 */
    printf("%d\n", -0);          /* 0  */
    a = -5;
    printf("%d\n", -a);          /* 5  (double negation) */

    /* ============================================================
       TRAP-4: 比較運算子邊界值（>= 和 <= 在等於時必須為 true）
       學生常犯：把 >= 實作成 >，導致 5>=5 回傳 false
       ============================================================ */
    a = 5;
    if (a >= 5) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a <= 5) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a > 5)  { printf("1\n"); } else { printf("0\n"); }   /* 0 */
    if (a < 5)  { printf("1\n"); } else { printf("0\n"); }   /* 0 */
    if (0 >= 0) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    a = -1;
    if (a >= -1){ printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (-2 > -3){ printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (-3 > -2){ printf("1\n"); } else { printf("0\n"); }   /* 0 */
    if (0 != 1) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (0 == 0) { printf("1\n"); } else { printf("0\n"); }   /* 1 */

    /* ============================================================
       TRAP-5: if-else 控制流陷阱
       學生常犯：dangling-else 綁定方向錯誤；condition=0 應走 else
       ============================================================ */

    /* 5-1: no-else, false condition → nothing prints */
    a = 1;
    if (a > 3) { printf("FAIL\n"); }
    printf("ok\n");                              /* ok */

    /* 5-2: dangling else binds to INNER if */
    a = 0;
    if (a > 0) if (a > 5) { printf("A\n"); } else { printf("B\n"); }
    printf("done\n");                            /* done (outer false, inner never reached) */

    a = 3;
    if (a > 0) if (a > 5) { printf("A\n"); } else { printf("B\n"); }
    /* expected: B  (outer true, inner false → else of INNER) */

    /* 5-3: zero as condition */
    int c;
    c = 0;
    if (c) { printf("FAIL\n"); } else { printf("zero\n"); }  /* zero */
    c = 5 - 5;
    if (c) { printf("FAIL\n"); } else { printf("zero2\n"); } /* zero2 */

    /* 5-4: deep else-if chain */
    a = 5;
    if      (a > 10) { printf("A\n"); }
    else if (a >  7) { printf("B\n"); }
    else if (a >  4) { printf("C\n"); }    /* C */
    else if (a >  1) { printf("D\n"); }
    else             { printf("E\n"); }

    /* ============================================================
       TRAP-6: printf 格式陷阱
       學生常犯：%f 不輸出 6 位小數、%d 不處理負數
       ============================================================ */
    printf("%f\n", 0.0);         /* 0.000000  NOT "0" */
    printf("%f\n", 1.0);         /* 1.000000 */
    float x;
    x = -1.5;
    printf("%f\n", x);           /* -1.500000 */
    printf("%d\n", -99);         /* -99 */
    printf("%d\n", 0);           /* 0 */
    printf("Hello\n");           /* Hello */
    printf("%d\n", 2+3*4);       /* 14 (expression as arg) */

    /* ============================================================
       TRAP-7: scanf 指標傳遞陷阱
       學生常犯：傳值而非傳指標，導致 scanf 無法修改變數
       ============================================================ */
    int n;
    scanf("%d", &n);              /* stdin: 42 */
    printf("%d\n", n);            /* 42 */
    n = n + 1;
    printf("%d\n", n);            /* 43 */

    int m;
    scanf("%d", &m);              /* stdin: -7 */
    printf("%d\n", m);            /* -7 */
    printf("%d\n", n + m);        /* 36 */

    float f;
    scanf("%f", &f);              /* stdin: 3.14 */
    printf("%f\n", f);            /* 3.140000 */

    float g;
    scanf("%f", &g);              /* stdin: -2.5 */
    printf("%f\n", g);            /* -2.500000 */
    printf("%f\n", f + g);        /* 0.640000 */

    /* ============================================================
       TRAP-8: ## 運算子陷阱
       學生常犯：優先順序錯誤（## 優先順序與乘除相同）；交換律
       ============================================================ */
    float ha; float hb; float hr;
    ha = 2.0; hb = 3.0;
    hr = ha ## hb;
    printf("%f\n", hr);           /* 17.000000 (2^3+3^2) */

    ha = 3.0; hb = 2.0;
    hr = ha ## hb;
    printf("%f\n", hr);           /* 17.000000 (3^2+2^3 = same) */

    ha = 1.0; hb = 1.0;
    hr = ha ## hb;
    printf("%f\n", hr);           /* 2.000000 */

    /* ## priority = * / → evaluated before + */
    ha = 1.0; hb = 1.0;
    hr = ha ## hb + 1.0;
    printf("%f\n", hr);           /* 3.000000  (2+1, NOT 1##2=...) */

    scanf("%f", &ha);             /* stdin: 2.0 */
    scanf("%f", &hb);             /* stdin: 3.0 */
    printf("%f\n", ha ## hb);    /* 17.000000 */

    /* ============================================================
       TRAP-9: while 迴圈邊界
       學生常犯：off-by-one（< vs <=），never-execute 情況
       ============================================================ */
    /* 9-1: never enters */
    int w;
    w = 10;
    while (w < 5) { printf("FAIL\n"); w = w + 1; }
    printf("%d\n", w);            /* 10 */

    /* 9-2: exactly once */
    w = 4;
    while (w < 5) { printf("%d\n", w); w = w + 1; }
    printf("%d\n", w);            /* 4 then 5 */

    /* 9-3: < vs <= boundary */
    int cnt;
    w = 0; cnt = 0;
    while (w < 5)  { cnt = cnt + 1; w = w + 1; }
    printf("%d\n", cnt);          /* 5 */
    w = 0; cnt = 0;
    while (w <= 5) { cnt = cnt + 1; w = w + 1; }
    printf("%d\n", cnt);          /* 6 */

    /* 9-4: doubling until >= 100 */
    w = 1;
    while (w < 100) { w = w * 2; }
    printf("%d\n", w);            /* 128 */

    /* 9-5: nested while 3x3=9 iterations */
    int ii; int jj;
    cnt = 0;
    ii = 0;
    while (ii < 3) {
        jj = 0;
        while (jj < 3) { cnt = cnt + 1; jj = jj + 1; }
        ii = ii + 1;
    }
    printf("%d\n", cnt);          /* 9 */

    /* ============================================================
       TRAP-10: 隱式型別轉換陷阱
       學生常犯：int=float 四捨五入（應截斷）；負數截斷方向
       ============================================================ */
    float tf; int ti;
    tf = 3.9;  ti = (int)tf; printf("%d\n", ti);  /* 3  NOT t4 */
    tf = -3.9; ti = (int)tf; printf("%d\n", ti);  /* -3 NOT neg4 */
    tf = 3.1;  ti = (int)tf; printf("%d\n", ti);  /* 3  */
    tf = -0.9; ti = (int)tf; printf("%d\n", ti);  /* 0  NOT neg1 */

    ti = 5;  tf = ti; printf("%f\n", tf);         /* 5.000000 */
    ti = -3; tf = ti; printf("%f\n", tf);         /* -3.000000 */
    ti = 0;  tf = ti; printf("%f\n", tf);         /* 0.000000 */

    /* int + float = float (implicit promotion) */
    int ia; float fb; float fr;
    ia = 1; fb = 2.5;
    fr = ia + fb; printf("%f\n", fr);             /* 3.500000 */
    fr = ia * fb; printf("%f\n", fr);             /* 2.500000 */

    /* ============================================================
       TRAP-11: 條件值型別混淆（i1 vs i32）
       學生常犯：直接用 i32 做 branch，LLVM 要求 i1
       ============================================================ */
    a = 0;
    if (a)  { printf("FAIL\n"); } else { printf("f0\n"); }  /* f0 */
    a = 1;
    if (a)  { printf("t1\n"); }                              /* t1 */
    a = 42;
    if (a)  { printf("t42\n"); }                             /* t42 */
    a = -1;
    if (a)  { printf("tn1\n"); }                             /* tn1 */
    a = 5; b = 5;
    if (a - b) { printf("FAIL\n"); } else { printf("diff0\n"); } /* diff0 */
    if (a - b + 1) { printf("diff1\n"); }                         /* diff1 */

    /* ============================================================
       TRAP-12: float 字面值精度陷阱
       學生常犯：浮點數 hex encoding 用 double bits 給 float 用
       ============================================================ */
    printf("%d\n", 1/3);          /* 0 (int division) */
    printf("%f\n", 1.0/3.0);      /* 0.333333 (float division) */
    x = 3.14;
    printf("%f\n", x);            /* 3.140000 */
    x = 0.5;
    printf("%f\n", x + x);        /* 1.000000 */

    /* ============================================================
       TRAP-13: 區塊作用域（變數修改應持久）
       ============================================================ */
    a = 5;
    if (a > 0) { a = 99; }
    printf("%d\n", a);            /* 99 (modified inside if persists) */

    a = 0;
    while (a < 3) { a = a + 1; }
    printf("%d\n", a);            /* 3 (while modification persists) */

    /* ============================================================
       TRAP-14: 複雜運算式組合
       ============================================================ */
    a = 3; b = 4;
    printf("%d\n", a*a + b*b);    /* 25 */
    printf("%d\n", (a+b)*(a-b));  /* -7 */
    a = 2; b = 3; c = 4;
    printf("%d\n", a+b*c-a);      /* 12 */

    /* ============================================================
       TRAP-15: printf 以運算式作為參數
       ============================================================ */
    a = 3; b = 4;
    printf("%d\n", a + b);        /* 7  */
    printf("%d\n", a * b - 1);    /* 11 */
    x = 1.5;
    printf("%f\n", x * 2.0);      /* 3.000000 */
    printf("%d\n", 2 + 3 * 4);    /* 14 */

    return 0;
}
