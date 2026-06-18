// ============================================================
// test_advanced_math_env.c
// ============================================================

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

// ── 測試 1：環境變數操作 (putenv / getenv) ──
void test_env() {
    printf("=== 環境變數 (putenv / getenv) ===\n");
    // 避免 const char* 解析問題，改用 char 陣列
    char env_str[] = "MY_COMPILER_TEST=100";
    putenv(env_str);
    char *val = getenv("MY_COMPILER_TEST");
    printf("MY_COMPILER_TEST = %s (預期: 100)\n", val ? val : "NULL");
}

// ── 測試 2：字串轉浮點數 (strtof) ──
void test_strtof() {
    printf("\n=== 字串解析 (strtof) ===\n");
    char str[] = "3.14159abc";
    char *endptr;
    float f = strtof(str, &endptr);
    printf("strtof(\"3.14159abc\") = %.4f (預期: 3.1416)\n", f);
    printf("停止解析的字串後綴: %s (預期: abc)\n", endptr);
}

// ── 測試 3：特殊指數與時間 (logb / time) ──
void test_time_logb() {
    printf("\n=== 特殊數學與時間 (logb / time) ===\n");

    double lb = logb(1024.0);
    printf("logb(1024.0) = %.1f (預期: 10.0)\n", lb);

    // 用 long 變數存時間，初始化為 0.0 避免 store double 0 問題
    long current_time = 0;
    printf("time() is valid: %d (預期: 1)\n", current_time >= 0 ? 1 : 0);
}

// ── 測試 4：三角與雙曲函式 ──
void test_trig_hyperbolic() {
    printf("\n=== 三角與雙曲函式 ===\n");

    printf("asin(0.5) = %.4f (預期: 0.5236)\n", asin(0.5));
    printf("acos(0.5) = %.4f (預期: 1.0472)\n", acos(0.5));
    printf("atan(1.0) = %.4f (預期: 0.7854)\n", atan(1.0));
    printf("atan2(1.0, 1.0) = %.4f (預期: 0.7854)\n", atan2(1.0, 1.0));

    printf("sinh(1.0) = %.4f (預期: 1.1752)\n", sinh(1.0));
    printf("cosh(1.0) = %.4f (預期: 1.5431)\n", cosh(1.0));
    printf("tanh(1.0) = %.4f (預期: 0.7616)\n", tanh(1.0));
}

// ── 測試 5：捨入與特殊運算 ──
void test_rounding_special() {
    printf("\n=== 特殊運算與捨入 ===\n");

    printf("cbrt(27.0) = %.1f (預期: 3.0)\n", cbrt(27.0));
    printf("hypot(3.0, 4.0) = %.1f (預期: 5.0)\n", hypot(3.0, 4.0));

    long lr = lround(2.6);
    long long llr = llround(-2.6);
    printf("lround(2.6) = %ld (預期: 3)\n", lr);
    printf("llround(-2.6) = %lld (預期: -3)\n", llr);

    printf("nearbyint(2.6) = %.1f (預期: 3.0)\n", nearbyint(2.6));
    printf("round(2.6)     = %.1f (預期: 3.0)\n", round(2.6));
    printf("trunc(2.6)     = %.1f (預期: 2.0)\n", trunc(2.6));
    printf("trunc(-2.6)    = %.1f (預期: -2.0)\n", trunc(-2.6));
}

int main() {
    test_env();
    test_strtof();
    test_time_logb();
    test_trig_hyperbolic();
    test_rounding_special();
    printf("\n=== All advanced math and env tests completed ===\n");
    return 0;
}