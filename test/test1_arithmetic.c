/* test1_arithmetic.c
   測試項目:
   - int / float 變數宣告與賦值
   - 四則運算 + - * /
   - 運算子優先權 (先乘除後加減)
   - 比較運算: > >= < <= == !=
   - if-then / if-then-else
   - printf %d %f
*/

int main() {
    int a;
    int b;
    int c;
    float x;
    float y;
    float z;

    /* --- 整數四則運算 --- */
    a = 10;
    b = 3;

    c = a + b;
    printf("10 + 3 = %d\n", c);         /* 13 */

    c = a - b;
    printf("10 - 3 = %d\n", c);         /* 7 */

    c = a * b;
    printf("10 * 3 = %d\n", c);         /* 30 */

    c = a / b;
    printf("10 / 3 = %d\n", c);         /* 3  (integer division) */

    /* --- 運算子優先權 --- */
    c = a + b * 2;
    printf("10 + 3*2 = %d\n", c);       /* 16 */

    c = (a + b) * 2;
    printf("(10+3)*2 = %d\n", c);       /* 26 */

    c = a - b * 2 + 4;
    printf("10 - 3*2 + 4 = %d\n", c);  /* 8 */

    c = 100 - 1;
    a = 2;
    b = a + a * (100 - 1) - a / 2;
    printf("2 + 2*(100-1) - 2/2 = %d\n", b);   /* 199 */

    /* --- 浮點數四則運算 --- */
    x = 7.5;
    y = 2.5;

    z = x + y;
    printf("7.5 + 2.5 = %f\n", z);     /* 10.000000 */

    z = x - y;
    printf("7.5 - 2.5 = %f\n", z);     /* 5.000000 */

    z = x * y;
    printf("7.5 * 2.5 = %f\n", z);     /* 18.750000 */

    z = x / y;
    printf("7.5 / 2.5 = %f\n", z);     /* 3.000000 */

    /* --- 比較運算 + if-then --- */
    a = 5;
    b = 10;

    if (a < b)
        printf("5 < 10 is true\n");

    if (a > b)
        printf("WRONG\n");

    if (a <= 5)
        printf("5 <= 5 is true\n");

    if (a >= 6)
        printf("WRONG\n");

    if (a == 5)
        printf("5 == 5 is true\n");

    if (a != b)
        printf("5 != 10 is true\n");

    /* --- if-then-else --- */
    a = 42;
    b = 42;

    if (a == b)
        printf("a == b: equal\n");
    else
        printf("WRONG\n");

    if (a != b)
        printf("WRONG\n");
    else
        printf("a != b is false: correct\n");

    a = 100;
    b = 200;

    if (a >= b)
        printf("WRONG\n");
    else
        printf("100 >= 200 is false: correct\n");

    if (a <= b)
        printf("100 <= 200 is true\n");
    else
        printf("WRONG\n");

    /* --- 邊界值 --- */
    a = 0;
    if (a == 0)
        printf("zero check ok\n");

    a = -5;
    b = -3;
    c = a + b;
    printf("-5 + -3 = %d\n", c);        /* -8 */

    c = a * b;
    printf("-5 * -3 = %d\n", c);        /* 15 */

    c = a - b;
    printf("-5 - -3 = %d\n", c);        /* -2 */

    return 0;
}
