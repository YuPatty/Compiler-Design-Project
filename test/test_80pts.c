int main(void) {

    /* =========================================
       SECTION 1: 基本 int 算術
       ========================================= */
    printf("--- 1. Int Arithmetic ---\n");
    int a;
    int b;
    a = 10;
    b = 3;
    printf("a+b = %d\n", a + b);
    printf("a-b = %d\n", a - b);
    printf("a*b = %d\n", a * b);
    printf("a/b = %d\n", a / b);
    printf("b+2*(100-1) = %d\n", b + 2 * (100 - 1));

    /* =========================================
       SECTION 2: 基本 float 算術
       ========================================= */
    printf("--- 2. Float Arithmetic ---\n");
    float x;
    float y;
    x = 3.0;
    y = 2.0;
    printf("x+y = %f\n", x + y);
    printf("x-y = %f\n", x - y);
    printf("x*y = %f\n", x * y);
    printf("x/y = %f\n", x / y);

    /* =========================================
       SECTION 3: printf 一個參數 / 兩個參數
       ========================================= */
    printf("--- 3. printf ---\n");
    printf("Hello\n");
    printf("World\n");
    int p;
    p = 42;
    printf("p = %d\n", p);
    float f;
    f = 1.5;
    printf("f = %f\n", f);

    /* =========================================
       SECTION 4: 比較運算全部六種
       ========================================= */
    printf("--- 4. Comparison ---\n");
    int m;
    int n;
    m = 5;
    n = 3;
    if (m > n)  printf("m>n: 1\n");
    if (m >= n) printf("m>=n: 1\n");
    if (n < m)  printf("n<m: 1\n");
    if (n <= m) printf("n<=m: 1\n");
    if (m == 5) printf("m==5: 1\n");
    if (n != 5) printf("n!=5: 1\n");
    if (m == n) printf("WRONG\n");
    if (m != n) printf("m!=n: 1\n");

    /* =========================================
       SECTION 5: if-then
       ========================================= */
    printf("--- 5. if-then ---\n");
    int v;
    v = 7;
    if (v > 0)
        printf("positive\n");
    if (v > 100)
        printf("WRONG\n");

    /* =========================================
       SECTION 6: if-then-else
       ========================================= */
    printf("--- 6. if-then-else ---\n");
    if (v > 10) {
        printf("WRONG\n");
    } else {
        printf("not big\n");
    }
    if (v > 0) {
        printf("positive2\n");
    } else {
        printf("WRONG\n");
    }

    /* =========================================
       SECTION 7: 巢狀 if（三層）
       ========================================= */
    printf("--- 7. Nested if ---\n");
    int q;
    q = 5;
    if (q > 0) {
        if (q > 3) {
            if (q > 7) {
                printf("WRONG\n");
            } else {
                printf("3<q<=7\n");
            }
        } else {
            printf("WRONG\n");
        }
    } else {
        printf("WRONG\n");
    }

    /* =========================================
       SECTION 8: ## 基本運算
       ========================================= */
    printf("--- 8. ## operator ---\n");
    float ha;
    float hb;
    float hr;
    ha = 2.0;
    hb = 3.0;
    hr = ha ## hb;
    printf("2.0##3.0 = %f\n", hr);

    /* =========================================
       SECTION 9: ## 優先權（與 * / 相同）
       ========================================= */
    printf("--- 9. ## precedence ---\n");
    float pa;
    float pb;
    float pc;
    float pr;
    pa = 2.0;
    pb = 3.0;
    pc = 4.0;
    pr = pa + pb ## pc;
    printf("2+(3##4) = %f\n", pr);
    pr = pa ## pb + pc;
    printf("(2##3)+4 = %f\n", pr);
    pr = pa ## pb * pc;
    printf("(2##3)*4 = %f\n", pr);

    /* =========================================
       SECTION 10: 隱式型別轉換 float→int
       ========================================= */
    printf("--- 10. Implicit: float->int ---\n");
    float pi;
    int ti;
    pi = 3.99;
    ti = pi;
    printf("3.99->int = %d\n", ti);
    pi = -2.9;
    ti = pi;
    printf("-2.9->int = %d\n", ti);
    pi = 0.9;
    ti = pi;
    printf("0.9->int = %d\n", ti);

    /* =========================================
       SECTION 11: 隱式型別轉換 int→float
       ========================================= */
    printf("--- 11. Implicit: int->float ---\n");
    int ia;
    float iaf;
    ia = 7;
    iaf = ia;
    printf("7->float = %f\n", iaf);
    ia = 0;
    iaf = ia;
    printf("0->float = %f\n", iaf);

    /* =========================================
       SECTION 12: 混合算術 int op float
       ========================================= */
    printf("--- 12. Mixed arithmetic ---\n");
    float mx;
    mx = 7 + 1.5;
    printf("7+1.5 = %f\n", mx);
    mx = 1.5 + 7;
    printf("1.5+7 = %f\n", mx);
    mx = 3 * 2.5;
    printf("3*2.5 = %f\n", mx);
    int mn;
    mn = 10 + 2.9;
    printf("(int)(10+2.9) = %d\n", mn);

    /* =========================================
       SECTION 13: 負數邊界
       ========================================= */
    printf("--- 13. Negative numbers ---\n");
    int na;
    int nb;
    na = -5;
    nb = -3;
    printf("-5+(-3) = %d\n", na + nb);
    printf("-5*(-3) = %d\n", na * nb);
    printf("-5/(-3) = %d\n", na / nb);
    printf("-5-(-3) = %d\n", na - nb);
    float nf;
    nf = -3.14;
    printf("-3.14 = %f\n", nf);

    /* =========================================
       SECTION 14: 零邊界
       ========================================= */
    printf("--- 14. Zero edge cases ---\n");
    int z;
    z = 0;
    printf("0*999 = %d\n", z * 999);
    printf("0+1 = %d\n", z + 1);
    float fz;
    fz = 0.0;
    printf("0.0+1.0 = %f\n", fz + 1.0);
    if (z == 0) printf("z==0: 1\n");
    if (z != 0) printf("WRONG\n");

    /* =========================================
       SECTION 15: 複雜運算式
       ========================================= */
    printf("--- 15. Complex expr ---\n");
    int cx;
    cx = (3 + 4) * (2 - 1) + 10 / 2;
    printf("(3+4)*(2-1)+10/2 = %d\n", cx);
    cx = 2 * 3 + 4 * 5;
    printf("2*3+4*5 = %d\n", cx);
    cx = 100 - 50 - 25;
    printf("100-50-25 = %d\n", cx);

    /* =========================================
       SECTION 16: scanf %d
       ========================================= */
    printf("--- 16. scanf %%d ---\n");
    int sn;
    printf("Enter int: ");
    scanf("%d", &sn);
    printf("Got: %d\n", sn);

    /* =========================================
       SECTION 17: scanf %f
       ========================================= */
    printf("--- 17. scanf %%f ---\n");
    float sf;
    printf("Enter float: ");
    scanf("%f", &sf);
    printf("Got: %f\n", sf);

    /* =========================================
       SECTION 18: 比較 float（邊界）
       ========================================= */
    printf("--- 18. Float comparison ---\n");
    float fa;
    float fb;
    fa = 1.5;
    fb = 2.5;
    if (fa < fb) printf("1.5<2.5: 1\n");
    if (fa <= fb) printf("1.5<=2.5: 1\n");
    if (fb > fa) printf("2.5>1.5: 1\n");
    if (fb >= fa) printf("2.5>=1.5: 1\n");
    fa = 1.5;
    fb = 1.5;
    if (fa == fb) printf("1.5==1.5: 1\n");
    if (fa != fb) printf("WRONG\n");

    /* =========================================
       SECTION 19: scope shadowing（同名變數）
       ========================================= */
    printf("--- 19. Scope shadowing ---\n");
    int sv;
    sv = 1;
    printf("outer sv = %d\n", sv);
    {
        int sv;
        sv = 2;
        printf("inner sv = %d\n", sv);
        {
            int sv;
            sv = 3;
            printf("innermost sv = %d\n", sv);
        }
        printf("inner sv after = %d\n", sv);
    }
    printf("outer sv after = %d\n", sv);

    /* =========================================
       SECTION 20: INT_MAX 邊界
       ========================================= */
    printf("--- 20. INT_MAX ---\n");
    int big;
    big = 2147483647;
    printf("INT_MAX = %d\n", big);
    if (big > 0) printf("INT_MAX>0: 1\n");

    return 0;
}
