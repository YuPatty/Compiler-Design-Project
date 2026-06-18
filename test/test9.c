int main() {

    /* ==============================
       1. Data Types: int, float
       ============================== */
    int a;
    int b;
    int c;
    float x;
    float y;
    float z;

    /* ==============================
       2. Arithmetic: + - * /
       ============================== */
    a = 10;
    b = 3;
    c = a + b;          printf("%d\n", c);   /* 13       */
    c = a - b;          printf("%d\n", c);   /* 7        */
    c = a * b;          printf("%d\n", c);   /* 30       */
    c = a / b;          printf("%d\n", c);   /* 3        */
    c = a + b * 2 - 1;  printf("%d\n", c);   /* 15       */
    c = (a + b) * 2 - 1;printf("%d\n", c);   /* 25       */
    c = 100 - 1;        printf("%d\n", c);   /* 99       */
    x = 1.5; y = 2.5;
    z = x + y;          printf("%f\n", z);   /* 4.000000 */
    z = x - y;          printf("%f\n", z);   /* -1.000000*/
    z = x * y;          printf("%f\n", z);   /* 3.750000 */
    z = y / x;          printf("%f\n", z);   /* 1.666667 */
    z = x + 1.0;        printf("%f\n", z);   /* 2.500000 */

    /* ==============================
       3. Comparison operators
       ============================== */
    a = 5; b = 3;
    if (a > b)  { printf("gt ok\n"); }
    if (a >= a) { printf("gte ok\n"); }
    if (b < a)  { printf("lt ok\n"); }
    if (b <= b) { printf("lte ok\n"); }
    if (a == 5) { printf("eq ok\n"); }
    if (a != b) { printf("neq ok\n"); }
    if (a > 10) { printf("FAIL\n"); } else { printf("gt fail ok\n"); }
    if (a == b) { printf("FAIL\n"); } else { printf("eq fail ok\n"); }

    /* ==============================
       4. if-then / if-then-else / nested
       ============================== */
    a = 7;
    if (a > 0) { printf("positive\n"); }
    if (a > 100) { printf("FAIL\n"); } else { printf("not big\n"); }
    if (a > 10) {
        printf("FAIL\n");
    } else {
        if (a > 5) { printf("nested mid\n"); }
        else       { printf("FAIL\n"); }
    }
    if (a > 10) {
        printf("FAIL\n");
    } else {
        if (a > 8) {
            printf("FAIL\n");
        } else {
            if (a == 7) { printf("deep nested ok\n"); }
            else        { printf("FAIL\n"); }
        }
    }

    /* ==============================
       5. printf: no param / %d / %f
       ============================== */
    printf("Hello\n");
    a = 42; printf("Number is %d\n", a);
    x = 3.14; printf("%f\n", x);
    a = 0;  printf("%d\n", a);
    a = -1; printf("%d\n", a);
    x = 0.0; printf("%f\n", x);

    /* ==============================
       6. scanf: %d / %f
       ============================== */
    scanf("%d", &a); printf("%d\n", a);
    scanf("%f", &x); printf("%f\n", x);

    /* ==============================
       7. ## operator  (a^b + b^a)
       ============================== */
    x = 2.0; y = 3.0;
    z = x ## y; printf("%f\n", z);   /* 17.000000 (2^3+3^2=8+9) */
    x = 1.0; y = 1.0;
    z = x ## y; printf("%f\n", z);   /* 2.000000  (1+1)         */
    x = 2.0; y = 2.0;
    z = x ## y; printf("%f\n", z);   /* 8.000000  (4+4)         */

    /* ==============================
       8. Boundary: zero / neg / large
       ============================== */
    a = 0; b = 0; c = a + b; printf("%d\n", c);     /* 0    */
    a = -5; b = 3;
    c = a + b; printf("%d\n", c);                    /* -2   */
    c = a * b; printf("%d\n", c);                    /* -15  */
    a = 1000000; b = 999999;
    c = a - b; printf("%d\n", c);                    /* 1    */
    x = 0.0; y = 1.5;
    z = x + y; printf("%f\n", z);                    /* 1.500000 */

    /* ==============================
       9. Comparison boundary
       ============================== */
    a = 0;
    if (a == 0)  { printf("zero eq ok\n"); }
    a = -1;
    if (a < 0)   { printf("neg lt ok\n"); }
    a = 0; b = 0;
    if (a >= b)  { printf("zero gte ok\n"); }
    if (a <= b)  { printf("zero lte ok\n"); }
    if (a != 1)  { printf("zero neq ok\n"); }

    return 0;
}