/* =====================================================
   test_preprocessor.c
   七、預處理器
   1. #define / #undef
   2. #ifdef / #ifndef / #else / #endif
   3. 科學記號（1.5e3、3.14f）
   ===================================================== */

#define MAX 100
#define MIN 0
#define PI 3.14159
#define VERSION 2
#define DEBUG
#define BUFFER_SIZE 64
#define HALF 0.5
#define NEG_ONE -1

int main(void) {

    /* ---------------------------------------------------
       1. #define 基本替換
       --------------------------------------------------- */
    printf("--- 1. #define ---\n");

    int n;
    n = MAX;
    printf("MAX = %d\n", n);

    n = MIN;
    printf("MIN = %d\n", n);

    float f;
    f = PI;
    printf("PI = %f\n", f);

    n = VERSION;
    printf("VERSION = %d\n", n);

    n = BUFFER_SIZE;
    printf("BUFFER_SIZE = %d\n", n);

    f = HALF;
    printf("HALF = %f\n", f);

    n = NEG_ONE;
    printf("NEG_ONE = %d\n", n);

    int arr[MAX];
    arr[0] = 1;
    arr[99] = 99;
    printf("arr[0]=%d arr[MAX-1]=%d\n", arr[0], arr[99]);

    int sum;
    sum = MAX + MIN;
    printf("MAX+MIN = %d\n", sum);

    float area;
    area = PI * HALF;
    printf("PI*HALF = %f\n", area);

    /* ---------------------------------------------------
       1b. #undef 後不再展開
       --------------------------------------------------- */
    printf("--- 1b. #undef ---\n");

#undef MIN
#define MIN 999

    n = MIN;
    printf("MIN after undef+redefine = %d\n", n);

#undef VERSION
#define VERSION 99

    n = VERSION;
    printf("VERSION after undef+redefine = %d\n", n);

    /* ---------------------------------------------------
       2a. #ifdef
       --------------------------------------------------- */
    printf("--- 2a. #ifdef ---\n");

#ifdef DEBUG
    printf("DEBUG is defined\n");
#endif

#ifdef MAX
    printf("MAX is defined\n");
#endif

#ifdef UNDEFINED_MACRO
    printf("WRONG: should not print\n");
#endif

    printf("after #ifdef blocks\n");

    /* ---------------------------------------------------
       2b. #ifndef
       --------------------------------------------------- */
    printf("--- 2b. #ifndef ---\n");

#ifndef RELEASE
    printf("RELEASE not defined\n");
#endif

#ifndef DEBUG
    printf("WRONG: DEBUG is defined\n");
#endif

#ifndef UNDEFINED_MACRO
    printf("UNDEFINED_MACRO not defined\n");
#endif

    printf("after #ifndef blocks\n");

    /* ---------------------------------------------------
       2c. #ifdef / #else / #endif
       --------------------------------------------------- */
    printf("--- 2c. #ifdef-else ---\n");

#ifdef DEBUG
    printf("debug branch\n");
#else
    printf("WRONG: release branch\n");
#endif

#ifdef UNDEFINED_MACRO
    printf("WRONG: undefined branch\n");
#else
    printf("correct else branch\n");
#endif

    /* ---------------------------------------------------
       2d. #ifndef / #else / #endif
       --------------------------------------------------- */
    printf("--- 2d. #ifndef-else ---\n");

#ifndef RELEASE
    printf("no release branch\n");
#else
    printf("WRONG: release branch\n");
#endif

#ifndef DEBUG
    printf("WRONG: debug not defined\n");
#else
    printf("debug else branch\n");
#endif

    /* ---------------------------------------------------
       2e. 巢狀條件編譯
       --------------------------------------------------- */
    printf("--- 2e. nested ifdef ---\n");

#ifdef DEBUG
#ifdef MAX
    printf("DEBUG and MAX both defined\n");
#endif
#ifndef RELEASE
    printf("DEBUG defined, RELEASE not defined\n");
#endif
#endif

#ifdef RELEASE
    printf("WRONG: in RELEASE block\n");
#else
#ifdef DEBUG
    printf("not RELEASE, but DEBUG\n");
#endif
#endif


    /* ---------------------------------------------------
       2f. 函式型巨集 (Function-like Macro)            ← 新增
       --------------------------------------------------- */
    printf("--- 2f. function-like macro ---\n");

#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN2(a, b) ((a) < (b) ? (a) : (b))
#define SQUARE(x) ((x) * (x))
#define ABS(x) ((x) >= 0 ? (x) : -(x))
#define ADD(a, b) ((a) + (b))

    int fm1 = MAX(3, 7);
    printf("MAX(3,7) = %d\n", fm1);

    int fm2 = MIN2(3, 7);
    printf("MIN2(3,7) = %d\n", fm2);

    int fm3 = SQUARE(5);
    printf("SQUARE(5) = %d\n", fm3);

    int fm4 = ABS(-9);
    printf("ABS(-9) = %d\n", fm4);

    int fm5 = ABS(4);
    printf("ABS(4) = %d\n", fm5);

    int fm6 = ADD(10, 20);
    printf("ADD(10,20) = %d\n", fm6);

    // 巢狀使用
    int fm7 = MAX(SQUARE(2), SQUARE(3));
    printf("MAX(SQUARE(2),SQUARE(3)) = %d\n", fm7);

    /* ---------------------------------------------------
       3. 科學記號（FLOAT_NUM lexer rule）
       --------------------------------------------------- */
    printf("--- 3. Scientific notation ---\n");

    float s1;
    s1 = 1.5e2;
    printf("1.5e2 = %f\n", s1);

    float s2;
    s2 = 2.0E3;
    printf("2.0E3 = %f\n", s2);

    float s3;
    s3 = 1.0e-1;
    printf("1.0e-1 = %f\n", s3);

    float s4;
    s4 = 3.0E-2;
    printf("3.0E-2 = %f\n", s4);

    float s5;
    s5 = 1e4;
    printf("1e4 = %f\n", s5);

    float s6;
    s6 = 5e0;
    printf("5e0 = %f\n", s6);

    float s7;
    s7 = 3.14f;
    printf("3.14f = %f\n", s7);

    float s8;
    s8 = 2.718F;
    printf("2.718F = %f\n", s8);

    float sci_expr;
    sci_expr = 1.0e2 + 2.5e1;
    printf("1.0e2 + 2.5e1 = %f\n", sci_expr);

    float sci_mul;
    sci_mul = 2.0e1 * 3.0e1;
    printf("2.0e1 * 3.0e1 = %f\n", sci_mul);

    float sci_neg;
    sci_neg = -1.5e2;
    printf("-1.5e2 = %f\n", sci_neg);

    if (s1 > 100.0) printf("1.5e2 > 100 OK\n");
    if (s3 < 1.0)   printf("1.0e-1 < 1.0 OK\n");

    return 0;
}
