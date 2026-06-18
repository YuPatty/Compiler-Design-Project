// test_preprocessor.c
// 測試：#define 常數巨集、#ifdef/#ifndef/#else/#endif 條件編譯、#undef

#define MAX_VAL 100
#define MIN_VAL 0
#define PI_APPROX 3
#define DEBUG 1
#define VERSION 2

int main(void) {
    printf("=== #define 常數替換 ===\n");
    printf("MAX_VAL = %d\n", MAX_VAL);      // 100
    printf("MIN_VAL = %d\n", MIN_VAL);      // 0
    printf("PI_APPROX = %d\n", PI_APPROX);  // 3

    printf("=== #define 在運算中 ===\n");
    int range;
    range = MAX_VAL - MIN_VAL;
    printf("range = %d\n", range);  // 100

    int area;
    area = PI_APPROX * 5 * 5;
    printf("PI_APPROX*25 = %d\n", area);  // 75

    printf("=== #ifdef / #endif ===\n");
#ifdef DEBUG
    printf("DEBUG mode is ON\n");   // 應該印出
#endif

#ifdef RELEASE
    printf("RELEASE mode\n");       // 不應印出（未定義）
#endif

    printf("=== #ifndef ===\n");
#ifndef RELEASE
    printf("RELEASE not defined\n"); // 應該印出
#endif

#ifndef DEBUG
    printf("DEBUG not defined\n");   // 不應印出
#endif

    printf("=== #ifdef / #else / #endif ===\n");
#ifdef DEBUG
    printf("Branch: DEBUG\n");   // 應該印出
#else
    printf("Branch: NOT DEBUG\n");
#endif

    printf("=== VERSION check ===\n");
#ifdef VERSION
    printf("VERSION = %d\n", VERSION);  // 2
#endif

    printf("=== #undef ===\n");
#undef DEBUG
#ifdef DEBUG
    printf("DEBUG still defined\n");  // 不應印出
#else
    printf("DEBUG was undef-ed\n");   // 應該印出
#endif

    return 0;
}
