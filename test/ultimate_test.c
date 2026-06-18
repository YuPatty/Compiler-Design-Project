
int main() {

    /* ============================================================
       SECTION 1: ARITHMETIC TRAPS
       - Integer division truncation (not rounding)
       - Operator precedence (*, / before +, -)
       - Left-to-right associativity
       - Unary minus on expression
       - Negative number arithmetic
       ============================================================ */

    int a; int b; int c;

    /* 1-1: int division truncates toward zero, not floor */
    a = 7;  b = 2;  c = a / b;    printf("%d\n", c);   /* 3  */
    a = -7; b = 2;  c = a / b;    printf("%d\n", c);   /* -3 (NOT -4) */
    a = 7;  b = -2; c = a / b;    printf("%d\n", c);   /* -3 */
    a = -7; b = -2; c = a / b;    printf("%d\n", c);   /* 3  */
    a = 1;  b = 2;  c = a / b;    printf("%d\n", c);   /* 0  */
    a = -1; b = 2;  c = a / b;    printf("%d\n", c);   /* 0  (NOT -1) */

    /* 1-2: Strict precedence */
    c = 2 + 3 * 4;                printf("%d\n", c);   /* 14 */
    c = 10 - 2 * 3 + 1;           printf("%d\n", c);   /* 5  */
    c = 100 / 10 / 2;              printf("%d\n", c);   /* 5 (left-to-right) */
    c = 2 * 3 + 4 * 5 - 1;        printf("%d\n", c);   /* 25 */

    /* 1-3: Unary minus */
    a = 5;
    c = -a;                        printf("%d\n", c);   /* -5 */
    c = -a + 10;                   printf("%d\n", c);   /* 5  */
    c = a + -3;                    printf("%d\n", c);   /* 2  */
    c = -a * -a;                   printf("%d\n", c);   /* 25 */

    /* 1-4: Zero edge cases */
    a = 0; b = 5;
    c = a * b;                     printf("%d\n", c);   /* 0  */
    c = a + b;                     printf("%d\n", c);   /* 5  */
    c = b - b;                     printf("%d\n", c);   /* 0  */

    /* ============================================================
       SECTION 2: FLOAT ARITHMETIC TRAPS
       - Float literal with and without f suffix
       - Float division (not integer division)
       - Negative float
       - printf %f always 6 decimal places
       ============================================================ */

    float x; float y; float z;

    /* 2-1: Basic float ops */
    x = 1.0; y = 3.0;
    z = x / y;                     printf("%f\n", z);   /* 0.333333 */
    x = 2.5; y = 2.5;
    z = x + y;                     printf("%f\n", z);   /* 5.000000 */
    z = x * y;                     printf("%f\n", z);   /* 6.250000 */
    z = x - y;                     printf("%f\n", z);   /* 0.000000 */

    /* 2-2: Negative float */
    x = -1.5; y = 2.0;
    z = x * y;                     printf("%f\n", z);   /* -3.000000 */
    z = x + y;                     printf("%f\n", z);   /* 0.500000  */

    /* 2-3: Float vs int division trap */
    a = 1; b = 3;
    c = a / b;                     printf("%d\n", c);   /* 0 (int div) */
    x = 1.0; y = 3.0;
    z = x / y;                     printf("%f\n", z);   /* 0.333333 (float div) */

    /* ============================================================
       SECTION 3: COMPARISON OPERATOR TRAPS
       - All 6 operators at boundary values
       - Equal boundary (>=, <=)
       - Negative comparisons
       - Zero comparisons
       ============================================================ */

    /* 3-1: All 6 operators, true case */
    a = 5; b = 3;
    if (a > b)  { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a >= b) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (b < a)  { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (b <= a) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a == 5) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a != b) { printf("1\n"); } else { printf("0\n"); }   /* 1 */

    /* 3-2: Boundary: equal values - >= and <= must be TRUE */
    a = 5; b = 5;
    if (a >= b) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a <= b) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a > b)  { printf("1\n"); } else { printf("0\n"); }   /* 0 */
    if (a < b)  { printf("1\n"); } else { printf("0\n"); }   /* 0 */

    /* 3-3: Negative number comparisons */
    a = -1; b = -2;
    if (a > b)  { printf("1\n"); } else { printf("0\n"); }   /* 1 (-1 > -2) */
    if (b < a)  { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    a = -1; b = 0;
    if (a < b)  { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a != b) { printf("1\n"); } else { printf("0\n"); }   /* 1 */

    /* 3-4: Zero comparisons */
    a = 0;
    if (a == 0) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a >= 0) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a <= 0) { printf("1\n"); } else { printf("0\n"); }   /* 1 */
    if (a > 0)  { printf("1\n"); } else { printf("0\n"); }   /* 0 */
    if (a < 0)  { printf("1\n"); } else { printf("0\n"); }   /* 0 */

    /* ============================================================
       SECTION 4: IF-ELSE TRAPS
       - Dangling else (else binds to nearest if)
       - Empty then-branch via compound stmt
       - Condition that is exactly 0 or non-zero
       - Nested if-else chains
       ============================================================ */

    /* 4-1: Dangling else - else goes with INNER if */
    a = 0;
    if (a > 0)
        if (a > 5) { printf("A\n"); }
        else       { printf("B\n"); }   /* B only if a>0 but <=5; here a=0 so nothing */
    /* expected: (nothing) */

    a = 3;
    if (a > 0)
        if (a > 5) { printf("A\n"); }
        else       { printf("B\n"); }   /* a>0, a<=5 -> B */
    /* expected: B */

    /* 4-2: Multiple if-else chain */
    a = 7;
    if      (a > 10) { printf("big\n"); }
    else if (a > 5)  { printf("mid\n"); }   /* 7 > 5 -> mid */
    else if (a > 0)  { printf("small\n"); }
    else             { printf("neg\n"); }

    /* 4-3: if condition is result of comparison (i1 type) */
    a = 5; b = 3;
    c = a - b;   /* c = 2 */
    if (c) { printf("nonzero\n"); }         /* 1 */
    c = a - a;   /* c = 0 */
    if (c) { printf("FAIL\n"); } else { printf("zero\n"); }  /* zero */

    /* 4-4: Deep nested */
    a = 5;
    if (a > 0) {
        if (a > 3) {
            if (a > 7) { printf("big\n"); }
            else        { printf("mid\n"); }   /* mid */
        } else {
            printf("small\n");
        }
    } else {
        printf("neg\n");
    }

    /* ============================================================
       SECTION 5: PRINTF TRAPS
       - %d with negative numbers
       - %f always 6 decimal places (even for .0)
       - printf with no args
       - printf result used after (side effect only)
       ============================================================ */

    /* 5-1: %d negative */
    a = -42; printf("%d\n", a);              /* -42 */
    a = 0;   printf("%d\n", a);              /*   0 */
    a = 2147483647; printf("%d\n", a);       /* 2147483647 (INT_MAX) */

    /* 5-2: %f always 6 decimal places */
    x = 0.0;   printf("%f\n", x);            /* 0.000000 */
    x = 1.0;   printf("%f\n", x);            /* 1.000000 */
    x = -1.0;  printf("%f\n", x);            /* -1.000000 */
    x = 100.0; printf("%f\n", x);            /* 100.000000 */
    x = 3.14;  printf("%f\n", x);            /* 3.140000 */

    /* 5-3: No-arg printf */
    printf("HELLO\n");
    printf("LINE2\n");

    /* ============================================================
       SECTION 6: SCANF TRAPS
       - scanf then immediately use
       - scanf into float then print as %d would be wrong
       - Multiple scanf calls
       ============================================================ */

    scanf("%d", &a);    printf("%d\n", a);     /* stdin: 42 -> 42 */
    scanf("%d", &b);    printf("%d\n", b);     /* stdin: -7 -> -7 */
    c = a + b;          printf("%d\n", c);     /* 35 */

    scanf("%f", &x);    printf("%f\n", x);     /* stdin: 3.14 -> 3.140000 */
    scanf("%f", &y);    printf("%f\n", y);     /* stdin: -2.5 -> -2.500000 */
    z = x + y;          printf("%f\n", z);     /* 0.640000 */

    /* ============================================================
       SECTION 7: ## OPERATOR TRAPS
       - Both operands MUST be float
       - Priority same as * /
       - a ## b = a^b + b^a (uses runtime)
       - Result is float
       ============================================================ */

    /* 7-1: Basic ## */
    x = 2.0; y = 3.0;
    z = x ## y;          printf("%f\n", z);   /* 8+9 = 17.000000 */

    /* 7-2: ## in expression with other ops - priority = * / */
    x = 1.0; y = 1.0;
    z = x ## y + 1.0;    printf("%f\n", z);   /* (1+1)+1 = 3.000000 */

    /* 7-3: ## with equal operands */
    x = 2.0; y = 2.0;
    z = x ## y;           printf("%f\n", z);  /* 4+4 = 8.000000 */

    /* 7-4: ## commutativity check */
    x = 1.5; y = 2.5;
    float r1; float r2;
    r1 = x ## y;
    r2 = y ## x;
    if (r1 == r2) { printf("1\n"); } else { printf("0\n"); }  /* 1 */

    /* ============================================================
       SECTION 8: WHILE LOOP TRAPS
       - Loop that never executes (condition false from start)
       - Loop that executes exactly once
       - Off-by-one: <= vs <
       - Nested while
       ============================================================ */

    /* 8-1: Never executes */
    a = 10;
    while (a < 5) { printf("FAIL\n"); a = a + 1; }
    printf("%d\n", a);                /* 10 (unchanged) */

    /* 8-2: Executes exactly once */
    a = 4;
    while (a < 5) { printf("%d\n", a); a = a + 1; }
    printf("%d\n", a);                /* 4 then 5 */

    /* 8-3: Off-by-one: <= vs < */
    a = 0; c = 0;
    while (a < 5)  { c = c + 1; a = a + 1; }
    printf("%d\n", c);                /* 5 */
    a = 0; c = 0;
    while (a <= 5) { c = c + 1; a = a + 1; }
    printf("%d\n", c);                /* 6 */

    /* 8-4: Nested while */
    a = 0; c = 0;
    while (a < 3) {
        b = 0;
        while (b < 3) { c = c + 1; b = b + 1; }
        a = a + 1;
    }
    printf("%d\n", c);                /* 9 */

    /* ============================================================
       SECTION 9: IMPLICIT TYPE CONVERSION TRAPS
       - int = float (truncation, not rounding)
       - float = int (exact)
       - int op float -> float result
       - Truncation direction for negatives
       ============================================================ */

    /* 9-1: int = float truncates toward zero */
    x = 3.9;  a = (int)x;  printf("%d\n", a);   /* 3 (not 4) */
    x = 3.1;  a = (int)x;  printf("%d\n", a);   /* 3 */
    x = -3.9; a = (int)x;  printf("%d\n", a);   /* -3 (toward zero, not -4) */
    x = -3.1; a = (int)x;  printf("%d\n", a);   /* -3 */

    /* 9-2: float = int is exact for small integers */
    a = 7; x = a;          printf("%f\n", x);   /* 7.000000 */
    a = -3; x = a;         printf("%f\n", x);   /* -3.000000 */
    a = 0; x = a;          printf("%f\n", x);   /* 0.000000 */

    /* 9-3: int op float -> float */
    a = 1; y = 3.0;
    z = a + y;             printf("%f\n", z);   /* 4.000000 */
    z = a * y;             printf("%f\n", z);   /* 3.000000 */

    /* ============================================================
       SECTION 10: ASSIGNMENT EXPRESSION VALUE TRAPS
       - Assignment returns the assigned value
       - Chained assignments a = b = 5
       ============================================================ */

    /* 10-1: Assignment in expression context */
    a = 10;
    b = a;
    printf("%d\n", b);    /* 10 */

    a = 5; b = 3;
    a = a + b;
    printf("%d\n", a);    /* 8 */

    /* ============================================================
       SECTION 11: BOUNDARY VALUES
       - Large values
       - Computation that crosses zero
       - Float precision edge case
       ============================================================ */

    a = 1000000; b = 999999;
    c = a - b;             printf("%d\n", c);   /* 1 */
    c = a + b;             printf("%d\n", c);   /* 1999999 */
    c = a * 2;             printf("%d\n", c);   /* 2000000 */

    a = -100; b = 200;
    c = a + b;             printf("%d\n", c);   /* 100 */
    c = a * b;             printf("%d\n", c);   /* -20000 */

    /* ============================================================
       SECTION 12: COMPLEX EXPRESSIONS
       - Deeply nested parentheses
       - Long chains
       - Mix of unary and binary
       ============================================================ */

    a = 2; b = 3; c = 4;
    int d;
    d = (a + b) * (c - a);   printf("%d\n", d);   /* 5 * 2 = 10 */
    d = a + b * c - a;       printf("%d\n", d);   /* 2+12-2 = 12 */
    d = (a + b + c) * 2;     printf("%d\n", d);   /* 18 */
    d = a * a + b * b;       printf("%d\n", d);   /* 4+9 = 13 */

    /* 12-2: Chained if-else as expression context */
    a = 5;
    if (a > 0 && a < 10) { printf("in range\n"); }   /* in range */
    if (a < 0 || a > 3)  { printf("out\n"); }         /* out */

    return 0;
}
