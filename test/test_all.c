int main(void) {

    /* ========================
       TEST 1: int 算術 + printf
       ======================== */
    printf("=== TEST 1: Int Arithmetic ===\n");
    int a;
    int b;
    a = 10;
    b = 3;
    printf("a = %d\n", a);
    printf("b = %d\n", b);
    printf("a+b = %d\n", a + b);
    printf("a-b = %d\n", a - b);
    printf("a*b = %d\n", a * b);
    printf("a/b = %d\n", a / b);
    printf("b+2*(100-1) = %d\n", b + 2 * (100 - 1));

    /* ========================
       TEST 2: float 算術
       ======================== */
    printf("=== TEST 2: Float Arithmetic ===\n");
    float x;
    float y;
    x = 3.14;
    y = 2.0;
    printf("x = %f\n", x);
    printf("y = %f\n", y);
    printf("x+y = %f\n", x + y);
    printf("x-y = %f\n", x - y);
    printf("x*y = %f\n", x * y);
    printf("x/y = %f\n", x / y);

    /* ========================
       TEST 3: 六種比較運算
       ======================== */
    printf("=== TEST 3: Comparison ===\n");
    int p;
    int q;
    p = 5;
    q = 3;
    if (p > q)  printf("p>q OK\n");
    if (p >= q) printf("p>=q OK\n");
    if (q < p)  printf("q<p OK\n");
    if (q <= p) printf("q<=p OK\n");
    if (p == 5) printf("p==5 OK\n");
    if (q != 5) printf("q!=5 OK\n");
    if (p != q) printf("p!=q OK\n");

    /* ========================
       TEST 4: if-then / if-else / nested if
       ======================== */
    printf("=== TEST 4: if-then / if-else / Nested if ===\n");
    int v;
    v = 7;

    if (v > 0)
        printf("positive\n");

    if (v > 10) {
        printf("big\n");
    } else {
        printf("small\n");
    }

    if (v > 0) {
        if (v > 5) {
            if (v > 10) {
                printf("v>10\n");
            } else {
                printf("5<v<=10\n");
            }
        } else {
            printf("0<v<=5\n");
        }
    } else {
        printf("v<=0\n");
    }

    /* ========================
       TEST 5: scanf %d / %f
       ======================== */
    printf("=== TEST 5: scanf ===\n");
    int n;
    float f;
    printf("Enter int: ");
    scanf("%d", &n);
    printf("Got int: %d\n", n);
    printf("Enter float: ");
    scanf("%f", &f);
    printf("Got float: %f\n", f);

    /* ========================
       TEST 6: ## 運算子基本
       ======================== */
    printf("=== TEST 6: ## Operator ===\n");
    float ha;
    float hb;
    float hr;
    ha = 1.5;
    hb = 2.5;
    hr = ha ## hb;
    printf("1.5 ## 2.5 = %f\n", hr);
    ha = 2.0;
    hb = 3.0;
    hr = ha ## hb;
    printf("2.0 ## 3.0 = %f\n", hr);

    /* ========================
       TEST 7: ## 優先權 (與 * / 相同)
       ======================== */
    printf("=== TEST 7: ## Precedence ===\n");
    float pa;
    float pb;
    float pc;
    float pr;
    pa = 2.0;
    pb = 3.0;
    pc = 4.0;
    pr = pa + pb ## pc;
    printf("2.0 + 3.0##4.0 = %f\n", pr);
    pr = pa ## pb + pc;
    printf("2.0##3.0 + 4.0 = %f\n", pr);

    /* ========================
       TEST 8: Implicit Type Conversion
       ======================== */
    printf("=== TEST 8: Implicit Type Conversion ===\n");
    float pi;
    int truncated;
    pi = 3.99;
    truncated = pi;
    printf("3.99 -> int = %d\n", truncated);

    pi = -2.9;
    truncated = pi;
    printf("-2.9 -> int = %d\n", truncated);

    int ia;
    float iaf;
    ia = 7;
    iaf = ia;
    printf("7 -> float = %f\n", iaf);

    float mixed;
    mixed = ia + 1.5;
    printf("7 + 1.5 = %f\n", mixed);

    mixed = 1.5 + ia;
    printf("1.5 + 7 = %f\n", mixed);

    /* ========================
       TEST 9: 邊界條件
       ======================== */
    printf("=== TEST 9: Edge Cases ===\n");
    int na;
    int nb;
    na = -5;
    nb = -3;
    printf("(-5)+(-3) = %d\n", na + nb);
    printf("(-5)*(-3) = %d\n", na * nb);
    printf("(-5)/(-3) = %d\n", na / nb);

    int z;
    z = 0;
    printf("0*999 = %d\n", z * 999);

    int big;
    big = 2147483647;
    printf("INT_MAX = %d\n", big);

    int complex;
    complex = (3 + 4) * (2 - 1) + 10 / 2;
    printf("(3+4)*(2-1)+10/2 = %d\n", complex);

    /* ========================
       TEST 10: printf 各種組合
       ======================== */
    printf("=== TEST 10: printf Combinations ===\n");
    printf("no args\n");

    int tx;
    tx = 42;
    printf("%d\n", tx);

    float tf;
    tf = 3.14;
    printf("%f\n", tf);

    printf("Number is %d\n", tx);
    printf("Float is %f\n", tf);

    int tneg;
    tneg = -100;
    printf("neg = %d\n", tneg);

    float tfneg;
    tfneg = -3.14;
    printf("fneg = %f\n", tfneg);

    return 0;
}
