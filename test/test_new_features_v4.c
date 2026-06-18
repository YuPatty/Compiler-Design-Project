// test_new_features_v4.c
// 測試新增功能：
//   1. #pragma / #error / #warning / #line 靜默
//   2. __COUNTER__ / __DATE__ / __TIME__
//   3. __VA_ARGS__ 可變參數巨集
//   4. INFINITY / NAN / HUGE_VAL / M_PI 預定義常數
//   5. INT_MAX / INT_MIN / CHAR_MAX / SEEK_SET 預定義常數
//   6. fmin / fmax / fma / fdim / copysign
//   7. isnan / isinf / isfinite / signbit
//   8. getenv / system / atexit / _exit
//   9. volatile / restrict / _Bool 型別修飾詞
//  10. _Bool 型別
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

// ─── 測試 1：#pragma / #error(skipped) / #warning(skipped) 靜默 ───
#pragma once
#pragma GCC optimize("O2")
// #error  "this should not fire"     ← 只有取消註解才會觸發
// #warning "this should not fire"
#line 999  // 靜默忽略

// ─── 測試 2：__COUNTER__ ───
#define UNIQUE_ID __COUNTER__
#define UNIQUE_ID2 __COUNTER__

// ─── 測試 3：__DATE__ / __TIME__ ───
// __DATE__ 和 __TIME__ 在 preprocess 時展開為字串

// ─── 測試 4：__VA_ARGS__ 可變參數巨集 ───
#define LOG(fmt, ...) printf("[LOG] " fmt "\n", ##__VA_ARGS__)
#define SUM3(a, b, c) ((a) + (b) + (c))
#define WRAP(...)  printf(__VA_ARGS__)

// ─── 測試 5：常數巨集 ───
// INFINITY / NAN / M_PI / M_E / INT_MAX / INT_MIN / SEEK_SET 均預定義

// ─── 測試 6：volatile / restrict / _Bool ───
volatile int v_counter = 0;
_Bool flag = 1;

void test_qualifiers() {
    printf("=== volatile / restrict / _Bool ===\n");
    volatile int x = 42;
    _Bool b = 1;
    
    // ✨ 新增的 restrict 指標測試
    restrict int *ptr = 0;

    printf("volatile int x=%d (預期 42)\n", x);
    printf("_Bool b=%d (預期 1)\n", b);
    printf("global flag=%d (預期 1)\n", flag);
    
    // ✨ 驗證 restrict 指標
    if (ptr == 0) {
        printf("restrict ptr works! (預期執行到此行)\n");
    }
}

void test_constants() {
    printf("\n=== 預定義常數 ===\n");
    printf("INT_MAX  = %d (預期 2147483647)\n",   INT_MAX);
    printf("INT_MIN  = %d (預期 -2147483648)\n",  INT_MIN);
    printf("CHAR_MAX = %d (預期 127)\n",           CHAR_MAX);
    printf("SEEK_SET = %d (預期 0)\n",             SEEK_SET);
    printf("SEEK_CUR = %d (預期 1)\n",             SEEK_CUR);
    printf("SEEK_END = %d (預期 2)\n",             SEEK_END);
    printf("M_PI ~= %.5f (預期 3.14159)\n",        M_PI);
    printf("M_E  ~= %.5f (預期 2.71828)\n",        M_E);
    // ✨ 新補上的 5 個常數測試 ✨
    printf("HUGE_VAL > 1e300: %d (預期 1)\n",      HUGE_VAL > 1e300);
    printf("M_SQRT2 ~= %.5f (預期 1.41421)\n",     M_SQRT2);
    printf("M_LN2   ~= %.5f (預期 0.69314)\n",     M_LN2);
    printf("TRUE  = %d (預期 1)\n",                TRUE);
    printf("FALSE = %d (預期 0)\n",                FALSE);

    double inf = INFINITY;
    double nan = NAN;
    printf("INFINITY > 1e300: %d (預期 1)\n", inf > 1e300);
    printf("isnan(NAN) = %d (預期 非零)\n",   isnan(nan));
    printf("isinf(INF) = %d (預期 非零)\n",   isinf(inf));
}

void test_va_args() {
    printf("\n=== __VA_ARGS__ ===\n");
    LOG("hello");
    LOG("x=%d y=%d", 10, 20);
    WRAP("WRAP: %d + %d = %d\n", 3, 4, 7);
    int s = SUM3(1, 2, 3);
    printf("SUM3(1,2,3) = %d (預期 6)\n", s);
}

void test_counter_date() {
    printf("\n=== __COUNTER__ / __DATE__ / __TIME__ ===\n");
    int id1 = UNIQUE_ID;
    int id2 = UNIQUE_ID2;
    printf("UNIQUE_ID=%d UNIQUE_ID2=%d (預期 0 1，或遞增值)\n", id1, id2);
    printf("Compiled on: %s at %s\n", __DATE__, __TIME__);
}

void test_fmin_fmax_fma() {
    printf("\n=== fmin / fmax / fma / fdim / copysign ===\n");
    printf("fmin(3.0, 5.0) = %.1f (預期 3.0)\n",  fmin(3.0, 5.0));
    printf("fmax(3.0, 5.0) = %.1f (預期 5.0)\n",  fmax(3.0, 5.0));
    printf("fmin(-1.0,1.0) = %.1f (預期 -1.0)\n", fmin(-1.0, 1.0));
    printf("fma(2.0,3.0,4.0) = %.1f (預期 10.0)\n", fma(2.0, 3.0, 4.0));
    printf("fdim(5.0, 3.0) = %.1f (預期 2.0)\n",  fdim(5.0, 3.0));
    printf("fdim(3.0, 5.0) = %.1f (預期 0.0)\n",  fdim(3.0, 5.0));
    printf("copysign(3.0,-1.0)=%.1f (預期 -3.0)\n", copysign(3.0, -1.0));
}

void test_isnan_isinf() {
    printf("\n=== isnan / isinf / isfinite / signbit ===\n");
    double inf  = INFINITY;
    double nan  = NAN;
    double x    = 3.14;
    printf("isnan(3.14)  = %d (預期 0)\n",    isnan(x));
    printf("isnan(NAN)   = %d (預期 非零)\n", isnan(nan));
    printf("isinf(INF)   = %d (預期 非零)\n", isinf(inf));
    printf("isinf(3.14)  = %d (預期 0)\n",    isinf(x));
    printf("isfinite(INF)= %d (預期 0)\n",    isfinite(inf));
    printf("isfinite(pi) = %d (預期 非零)\n", isfinite(x));
    printf("signbit(-1.0)= %d (預期 非零)\n", signbit(-1.0));
    printf("signbit(1.0) = %d (預期 0)\n",    signbit(1.0));
}

void cleanup_func() {
    printf("atexit callback called!\n");
}

void test_env_system() {
    printf("\n=== getenv / system / atexit ===\n");

    // atexit 登記（程式結束時呼叫）
    atexit(cleanup_func);
    printf("atexit registered\n");

    // getenv
    char *path = getenv("PATH");
    if (path != 0) {
        printf("PATH 存在，長度>0: %d\n", strlen(path) > 0);
    } else {
        printf("PATH 未設定（可能在受限環境）\n");
    }

    // system（執行 echo）
    int ret = system("echo system_test_ok");
    printf("system() returned: %d (預期 0)\n", ret);

    //_exit(0);  // 直接結束程式，不呼叫 atexit 登記的函式
}

int main() {
    test_qualifiers();
    test_constants();
    test_va_args();
    test_counter_date();
    test_fmin_fmax_fma();
    test_isnan_isinf();
    test_env_system();
    printf("\n=== 所有測試完成 ===\n");
    return 0;
}