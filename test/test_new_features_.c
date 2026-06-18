/* =====================================================
   test_new_features.c
   測試四個新功能：
   1. typedef（基本型別 + struct）
   2. 科學記號（Scientific Notation）
   3. #define 巨集
   4. #ifdef / #ifndef 條件編譯
   ===================================================== */

/* --- Feature 3+4: #define 與 條件編譯 --- */
#define VERSION 2
#define PI 3.14159
#define MAX_SIZE 100
#define DEBUG

/* --- Feature 1: typedef 基本型別別名 --- */
typedef int MyInt;
typedef float Real;

/* --- Feature 1: typedef struct --- */
typedef struct Point {
    int x;
    int y;
} Point;

int main(void) {

    /* ==========================================
       Feature 1: typedef 基本型別
       ========================================== */
    printf("=== 1. typedef ===\n");
    MyInt a;
    a = 42;
    printf("MyInt a = %d\n", a);

    Real r;
    r = 3.14;
    printf("Real r = %f\n", r);

    /* ==========================================
       Feature 1: typedef struct
       ========================================== */
    printf("=== 1b. typedef struct ===\n");
    Point p;
    p.x = 10;
    p.y = 20;
    printf("Point p.x = %d\n", p.x);
    printf("Point p.y = %d\n", p.y);

    /* ==========================================
       Feature 2: 科學記號
       ========================================== */
    printf("=== 2. Scientific Notation ===\n");
    float f1;
    float f2;
    float f3;
    float f4;
    f1 = 1.5e2;
    f2 = 2.0E-1;
    f3 = 1e3;
    f4 = 3.0e0;
    printf("1.5e2  = %f\n", f1);
    printf("2.0E-1 = %f\n", f2);
    printf("1e3    = %f\n", f3);
    printf("3.0e0  = %f\n", f4);

    float sci_expr;
    sci_expr = 1.0e2 + 2.5e1;
    printf("1.0e2 + 2.5e1 = %f\n", sci_expr);

    /* ==========================================
       Feature 3: #define 巨集替換
       ========================================== */
    printf("=== 3. #define ===\n");
    int ver;
    ver = VERSION;
    printf("VERSION = %d\n", ver);

    float mypi;
    mypi = PI;
    printf("PI = %f\n", mypi);

    int sz;
    sz = MAX_SIZE;
    printf("MAX_SIZE = %d\n", sz);

    /* ==========================================
       Feature 4: #ifdef / #ifndef 條件編譯
       ========================================== */
    printf("=== 4. Conditional Compilation ===\n");

#ifdef DEBUG
    printf("DEBUG is defined\n");
#else
    printf("DEBUG is NOT defined\n");
#endif

#ifndef RELEASE
    printf("RELEASE is not defined\n");
#else
    printf("RELEASE is defined\n");
#endif

#ifdef VERSION
    printf("VERSION macro exists\n");
#endif

#ifndef UNDEFINED_MACRO
    printf("UNDEFINED_MACRO not defined (correct)\n");
#endif

    return 0;
}
