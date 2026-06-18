/* ============================================================
   ultimate_test.c
   助教終極驗收測資 — 80分基本功能全覆蓋
   不需要 scanf，直接執行即可對照預期輸出

   測試分區:
   [A] int/float 宣告與基本賦值
   [B] 四則運算優先權與括號
   [C] Unary minus（負號）
   [D] 整數除法截斷 vs 浮點除法
   [E] 連續賦值 (chain assignment)
   [F] 六種比較運算子
   [G] if-then（無else）
   [H] if-then-else
   [I] Dangling else 陷阱
   [J] 巢狀 if-else
   [K] printf 純字串（無第二參數）
   [L] printf %d / %f 雙參數
   [M] scanf %d / %f
   [N] ## 基本計算
   [O] ## 優先權高於 + -
   [P] ## 與 * / 左結合（最致命陷阱）
   [Q] ## 型別（float-only）與結果用於 if
   [R] 邊界值：0, 負數, 大數
   [S] 複合運算式壓力測試
   ============================================================ */

int main() {

    /* ===================== [A] 宣告與賦值 ===================== */
    int   a;
    int   b;
    int   c;
    float x;
    float y;
    float z;

    a = 10;
    b = 3;
    x = 1.5;
    y = 2.5;

    printf("=== [A] declaration ===\n");
    printf("a=%d\n", a);
    printf("b=%d\n", b);
    printf("x=%f\n", x);
    printf("y=%f\n", y);


    /* ===================== [B] 四則運算優先權 ===================== */
    printf("=== [B] arithmetic precedence ===\n");

    /* 基本四則 */
    c = a + b;
    printf("10+3=%d\n", c);              /* 13 */
    c = a - b;
    printf("10-3=%d\n", c);              /* 7  */
    c = a * b;
    printf("10*3=%d\n", c);              /* 30 */
    c = a / b;
    printf("10/3=%d\n", c);              /* 3  ← int 截斷 */

    /* 優先權：乘除先於加減 */
    c = a + b * 2;
    printf("10+3*2=%d\n", c);            /* 16，不是 26 */

    c = a - b * 2 + 4;
    printf("10-3*2+4=%d\n", c);          /* 8 */

    /* 括號覆寫 */
    c = (a + b) * 2;
    printf("(10+3)*2=%d\n", c);          /* 26 */

    /* 題目原始範例 */
    a = 2;
    b = a + a * (100 - 1) - a / 2;
    printf("2+2*(100-1)-2/2=%d\n", b);   /* 199 */

    /* 重設 */
    a = 10;
    b = 3;

    /* 浮點四則 */
    z = x + y;
    printf("1.5+2.5=%f\n", z);           /* 4.000000 */
    z = x * y;
    printf("1.5*2.5=%f\n", z);           /* 3.750000 */
    z = y - x;
    printf("2.5-1.5=%f\n", z);           /* 1.000000 */
    z = y / x;
    printf("2.5/1.5=%f\n", z);           /* 1.666667 */


    /* ===================== [C] Unary minus ===================== */
    printf("=== [C] unary minus ===\n");

    c = -a;
    printf("-10=%d\n", c);               /* -10 */

    c = -a + b;
    printf("-10+3=%d\n", c);             /* -7 */

    c = -a * b;
    printf("-10*3=%d\n", c);             /* -30 */

    c = -(a + b);
    printf("-(10+3)=%d\n", c);           /* -13 */

    c = -a * -b;
    printf("-10*-3=%d\n", c);            /* 30 */

    z = -x;
    printf("-1.5=%f\n", z);              /* -1.500000 */

    z = -x * y;
    printf("-1.5*2.5=%f\n", z);          /* -3.750000 */


    /* ===================== [D] 整數除法截斷 ===================== */
    printf("=== [D] integer division truncation ===\n");

    c = 7 / 2;
    printf("7/2=%d\n", c);              /* 3，不是 3.5 */

    c = -7 / 2;
    printf("-7/2=%d\n", c);             /* -3（toward zero）*/

    c = 1 / 3;
    printf("1/3=%d\n", c);              /* 0 */

    c = 10 / 10;
    printf("10/10=%d\n", c);            /* 1 */

    z = 7.0 / 2.0;
    printf("7.0/2.0=%f\n", z);          /* 3.500000 */

    z = 1.0 / 3.0;
    printf("1.0/3.0=%f\n", z);          /* 0.333333 */


    /* ===================== [E] 連鎖賦值 ===================== */
    printf("=== [E] chain assignment ===\n");

    a = b = 5;
    printf("a=%d b=%d\n", a, b);        /* a=5 b=5 */
    /* 注意：若不支援 chain assignment，此行應拆成兩行測 */


    /* ===================== [F] 六種比較運算子 ===================== */
    printf("=== [F] comparison operators ===\n");

    a = 5;
    b = 10;

    /* > */
    if (b > a)
        printf("10>5: true\n");
    if (a > b)
        printf("WRONG\n");

    /* >= */
    if (a >= 5)
        printf("5>=5: true\n");
    if (a >= 6)
        printf("WRONG\n");

    /* < */
    if (a < b)
        printf("5<10: true\n");
    if (b < a)
        printf("WRONG\n");

    /* <= */
    if (b <= 10)
        printf("10<=10: true\n");
    if (b <= 9)
        printf("WRONG\n");

    /* == */
    if (a == 5)
        printf("5==5: true\n");
    if (a == 6)
        printf("WRONG\n");

    /* != */
    if (a != b)
        printf("5!=10: true\n");
    if (a != 5)
        printf("WRONG\n");

    /* 浮點比較 */
    x = 1.5;
    y = 2.5;
    if (x < y)
        printf("1.5<2.5: true\n");
    if (y > x)
        printf("2.5>1.5: true\n");


    /* ===================== [G] if-then 無 else ===================== */
    printf("=== [G] if-then only ===\n");

    a = 1;
    if (a == 1)
        printf("a is 1\n");             /* 印出 */

    if (a == 0)
        printf("WRONG\n");              /* 不印 */

    if (a != 0)
        printf("a is nonzero\n");       /* 印出 */

    /* 條件為 0（false）時完全跳過 */
    b = 0;
    if (b)
        printf("WRONG\n");


    /* ===================== [H] if-then-else ===================== */
    printf("=== [H] if-then-else ===\n");

    a = 7;

    if (a > 10)
        printf("big\n");
    else
        printf("small\n");              /* small */

    if (a == 7)
        printf("seven\n");              /* seven */
    else
        printf("WRONG\n");

    if (a < 0)
        printf("WRONG\n");
    else
        printf("non-negative\n");       /* non-negative */


    /* ===================== [I] Dangling else 陷阱 ===================== */
    /* C 語言規則: else 配對最近的 if
       if(A) if(B) X; else Y;
       等同於:
       if(A) { if(B) X; else Y; }
       不是:
       if(A) { if(B) X; } else { Y; }
    */
    printf("=== [I] dangling else ===\n");

    a = 1;
    b = 0;

    if (a == 1)
        if (b == 1)
            printf("WRONG-inner\n");
        else
            printf("dangling-else-ok\n");   /* 印出（else 配 inner if）*/

    /* 第二個 dangling else 測試: outer if 為 false */
    a = 0;
    b = 0;

    if (a == 1)
        if (b == 1)
            printf("WRONG-inner2\n");
        else
            printf("WRONG-dangling2\n");    /* 不印（outer if false，整個跳過）*/

    printf("after-dangling\n");             /* 一定印出 */


    /* ===================== [J] 巢狀 if-else ===================== */
    printf("=== [J] nested if-else ===\n");

    a = 15;

    if (a > 20)
        printf("big\n");
    else
        if (a > 10)
            printf("medium\n");             /* medium */
        else
            printf("small\n");

    /* 三層巢狀 */
    a = 5;
    b = 3;
    c = 1;

    if (a > b)
        if (b > c)
            if (c > 0)
                printf("5>3>1>0: all true\n");  /* 印出 */
            else
                printf("WRONG\n");
        else
            printf("WRONG\n");
    else
        printf("WRONG\n");


    /* ===================== [K] printf 純字串 ===================== */
    printf("=== [K] printf string only ===\n");

    printf("Hello\n");
    printf("Number is 42\n");
    printf("test\n");


    /* ===================== [L] printf %d / %f ===================== */
    printf("=== [L] printf with args ===\n");

    a = 42;
    printf("Number is %d\n", a);        /* Number is 42 */

    x = 3.14;
    printf("Pi is %f\n", x);            /* Pi is 3.140000 */

    c = -99;
    printf("Neg: %d\n", c);             /* Neg: -99 */

    z = -0.5;
    printf("Neg float: %f\n", z);       /* Neg float: -0.500000 */

    /* 運算結果直接印 */
    a = 6;
    b = 7;
    c = a * b;
    printf("6*7=%d\n", c);             /* 6*7=42 */

    x = 2.0;
    y = 3.0;
    z = x * y;
    printf("2.0*3.0=%f\n", z);         /* 2.0*3.0=6.000000 */


    /* ===================== [M] scanf %d / %f ===================== */
    /* 本區需要互動，放在最後 */
    /* 建議測試輸入: 先輸入 6，再輸入 2.0 */
    printf("=== [M] scanf ===\n");
    printf("Enter int: \n");
    scanf("%d", &a);
    printf("got int: %d\n", a);

    printf("Enter float: \n");
    scanf("%f", &x);
    printf("got float: %f\n", x);

    /* 用讀入值做運算 */
    b = a * 2;
    printf("int*2: %d\n", b);

    y = x + 1.0;
    printf("float+1: %f\n", y);


    /* ===================== [N] ## 基本計算 ===================== */
    printf("=== [N] hash operator basic ===\n");

    x = 1.5;
    y = 2.5;
    z = x ## y;
    printf("1.5##2.5=%f\n", z);         /* 6.708524 */

    x = 2.0;
    y = 3.0;
    z = x ## y;
    printf("2.0##3.0=%f\n", z);         /* 17.000000 */

    x = 1.0;
    y = 1.0;
    z = x ## y;
    printf("1.0##1.0=%f\n", z);         /* 2.000000 */

    x = 4.0;
    y = 2.0;
    z = x ## y;
    printf("4.0##2.0=%f\n", z);         /* 32.000000 */

    /* 對稱性: a##b == b##a（此例正好對稱） */
    x = 2.0;
    y = 3.0;
    z = y ## x;
    printf("3.0##2.0=%f\n", z);         /* 3^2+2^3=9+8=17.000000 */


    /* ===================== [O] ## 優先權高於 + - ===================== */
    printf("=== [O] ## precedence over + - ===\n");

    x = 2.0;
    y = 3.0;
    z = 1.0;

    /* 1.0 + (2.0##3.0) = 1.0 + 17.0 = 18.0 */
    z = 1.0 + x ## y;
    printf("1.0+2.0##3.0=%f\n", z);     /* 18.000000 */

    /* (2.0##3.0) + 1.0 = 18.0 */
    z = x ## y + 1.0;
    printf("2.0##3.0+1.0=%f\n", z);     /* 18.000000 */

    /* 1.0 - (2.0##3.0) = 1.0 - 17.0 = -16.0 */
    z = 1.0 - x ## y;
    printf("1.0-2.0##3.0=%f\n", z);     /* -16.000000 */

    /* (2.0##3.0) - 1.0 = 16.0 */
    z = x ## y - 1.0;
    printf("2.0##3.0-1.0=%f\n", z);     /* 16.000000 */


    /* ===================== [P] ## 與 * 左結合（最致命陷阱）===================== */
    /* 左結合規則（優先權同 * /）:
       a * b ## c = (a*b) ## c    ← 正確
       a ## b * c = (a##b) * c    ← 正確

       錯誤實作（右結合）:
       a * b ## c = a * (b##c)    ← 錯誤
    */
    printf("=== [P] ## left-associativity with * ===\n");

    x = 2.0;
    y = 2.0;
    z = 3.0;

    /* (2.0 * 2.0) ## 3.0
       = 4.0 ## 3.0
       = 4^3 + 3^4 = 64 + 81 = 145.000000

       若右結合: 2.0 * (2.0##3.0) = 2.0 * 17.0 = 34.000000
       → 輸出 34 代表左結合實作錯誤！ */
    z = x * y ## z;
    printf("2.0*2.0##3.0=%f\n", z);     /* 145.000000  ← 關鍵！ */

    x = 2.0;
    y = 2.0;
    z = 3.0;

    /* (2.0 ## 2.0) * 3.0
       = (4+4) * 3.0 = 8 * 3.0 = 24.000000 */
    z = x ## y * z;
    printf("2.0##2.0*3.0=%f\n", z);     /* 24.000000 */

    /* ## 與 / 左結合 */
    x = 6.0;
    y = 2.0;
    z = 3.0;

    /* (6.0 / 2.0) ## 3.0
       = 3.0 ## 3.0
       = 3^3 + 3^3 = 27 + 27 = 54.000000 */
    z = x / y ## z;
    printf("6.0/2.0##3.0=%f\n", z);     /* 54.000000 */


    /* ===================== [Q] ## 型別與結果作為 if 條件 ===================== */
    printf("=== [Q] ## result in if ===\n");

    x = 2.0;
    y = 3.0;
    z = x ## y;                         /* 17.0 */

    if (z > 10.0)
        printf("##result>10: true\n");   /* true */
    else
        printf("WRONG\n");

    if (z > 20.0)
        printf("WRONG\n");
    else
        printf("##result<=20: true\n"); /* true */

    /* ## 結果用於進一步運算 */
    z = x ## y + 3.0;
    printf("##result+3=%f\n", z);       /* 20.000000 */

    /* ## 結果賦值後再用 */
    x = 2.0;
    y = 2.0;
    z = x ## y;                         /* 4+4=8 */
    z = z * 2.0;
    printf("(2.0##2.0)*2=%f\n", z);     /* 16.000000 */


    /* ===================== [R] 邊界值 ===================== */
    printf("=== [R] edge cases ===\n");

    /* 零 */
    a = 0;
    b = 0;
    c = a + b;
    printf("0+0=%d\n", c);              /* 0 */
    c = a * 999;
    printf("0*999=%d\n", c);            /* 0 */

    if (a == 0)
        printf("zero-eq: ok\n");

    if (a != 0)
        printf("WRONG\n");

    /* 負負得正 */
    a = -5;
    b = -3;
    c = a * b;
    printf("-5*-3=%d\n", c);            /* 15 */
    c = a + b;
    printf("-5+-3=%d\n", c);            /* -8 */
    c = a - b;
    printf("-5--3=%d\n", c);            /* -2 */

    /* 負數比較 */
    a = -1;
    b = 0;
    if (a < b)
        printf("-1<0: true\n");

    if (a > b)
        printf("WRONG\n");

    /* 大數運算 */
    a = 1000;
    b = 999;
    c = a * b;
    printf("1000*999=%d\n", c);         /* 999000 */

    c = a - b;
    printf("1000-999=%d\n", c);         /* 1 */

    /* float 精度 */
    x = 0.1;
    y = 0.2;
    z = x + y;
    printf("0.1+0.2=%f\n", z);          /* 0.300000（float 精度）*/

    x = 0.0;
    y = 1.0;
    z = x + y;
    printf("0.0+1.0=%f\n", z);          /* 1.000000 */

    /* 負 float */
    x = -3.5;
    y = 2.0;
    z = x * y;
    printf("-3.5*2.0=%f\n", z);         /* -7.000000 */


    /* ===================== [S] 壓力測試：複合運算式 ===================== */
    printf("=== [S] compound expressions ===\n");

    a = 3;
    b = 4;
    c = 5;

    /* (a+b) * c - a * b + c */
    /* = 7 * 5 - 3*4 + 5 = 35 - 12 + 5 = 28 */
    c = (a + b) * c - a * b + c;
    printf("(3+4)*5-3*4+5=%d\n", c);   /* 28 */

    a = 10;
    b = 3;
    c = 2;

    /* a / b * c = (10/3)*2 = 3*2 = 6（int 左結合）*/
    c = a / b * c;
    printf("10/3*2=%d\n", c);          /* 6 */

    /* 多層巢狀比較 */
    a = 5;
    b = 10;
    c = 15;

    if (a < b)
        if (b < c)
            printf("5<10<15: both true\n");
        else
            printf("WRONG\n");
    else
        printf("WRONG\n");

    /* if-else chain 模擬 */
    a = 50;

    if (a < 0)
        printf("negative\n");
    else
        if (a == 0)
            printf("zero\n");
        else
            if (a < 100)
                printf("small positive\n");  /* small positive */
            else
                printf("large\n");

    /* float 複合 */
    x = 3.0;
    y = 4.0;
    z = x * x + y * y;
    printf("3^2+4^2=%f\n", z);         /* 25.000000 */

    printf("=== ALL DONE ===\n");

    return 0;
}
