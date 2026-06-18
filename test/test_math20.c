// test_math20.c
// 驗證 20 個 math.h 函式：
// lround / llround / nearbyint / round / trunc /
// exp / exp2 / log2 / log10 / tan / asin / acos /
// atan / atan2 / sinh / cosh / tanh / cbrt / hypot

#include <stdio.h>
#include <math.h>

int main(void) {

    // ── lround：double → i64，遠離零方向四捨五入 ──
    printf("lround(2.5)   = %ld\n", lround(2.5));    //  3
    printf("lround(-2.5)  = %ld\n", lround(-2.5));   // -3
    printf("lround(2.3)   = %ld\n", lround(2.3));    //  2
    printf("lround(-2.7)  = %ld\n", lround(-2.7));   // -3

    // ── llround：同 lround，明確 i64 ──
    printf("llround(3.5)  = %ld\n", llround(3.5));   //  4
    printf("llround(-3.5) = %ld\n", llround(-3.5));  // -4
    printf("llround(1e15) = %ld\n", llround(1e15));  // 1000000000000000

    // ── nearbyint：銀行家捨入（round-to-even）──
    printf("nearbyint(2.5)  = %.1f\n", nearbyint(2.5));   // 2.0
    printf("nearbyint(3.5)  = %.1f\n", nearbyint(3.5));   // 4.0
    printf("nearbyint(-2.5) = %.1f\n", nearbyint(-2.5));  // -2.0
    printf("nearbyint(2.3)  = %.1f\n", nearbyint(2.3));   // 2.0
    printf("nearbyint(2.7)  = %.1f\n", nearbyint(2.7));   // 3.0

    // ── round：遠離零方向，回傳 double ──
    printf("round(2.5)  = %.1f\n", round(2.5));    // 3.0
    printf("round(-2.5) = %.1f\n", round(-2.5));   // -3.0
    printf("round(2.3)  = %.1f\n", round(2.3));    // 2.0

    // ── trunc：截斷小數（向零方向）──
    printf("trunc(2.9)  = %.1f\n", trunc(2.9));    // 2.0
    printf("trunc(-2.9) = %.1f\n", trunc(-2.9));   // -2.0
    printf("trunc(3.0)  = %.1f\n", trunc(3.0));    // 3.0

    // ── exp：e^x ──
    printf("exp(0.0) = %.6f\n", exp(0.0));   // 1.000000
    printf("exp(1.0) = %.6f\n", exp(1.0));   // 2.718282
    printf("exp(2.0) = %.6f\n", exp(2.0));   // 7.389056

    // ── exp2：2^x ──
    printf("exp2(0.0) = %.6f\n", exp2(0.0));   // 1.000000
    printf("exp2(3.0) = %.6f\n", exp2(3.0));   // 8.000000
    printf("exp2(10.0)= %.6f\n", exp2(10.0));  // 1024.000000

    // ── log2：log base 2 ──
    printf("log2(1.0)  = %.6f\n", log2(1.0));    // 0.000000
    printf("log2(8.0)  = %.6f\n", log2(8.0));    // 3.000000
    printf("log2(1024.0)=%.6f\n", log2(1024.0)); // 10.000000

    // ── log10：log base 10 ──
    printf("log10(1.0)   = %.6f\n", log10(1.0));    // 0.000000
    printf("log10(100.0) = %.6f\n", log10(100.0));  // 2.000000
    printf("log10(1000.0)= %.6f\n", log10(1000.0)); // 3.000000

    // ── tan：正切（弧度）──
    printf("tan(0.0)         = %.6f\n", tan(0.0));           // 0.000000
    printf("tan(0.785398)    = %.6f\n", tan(0.785398));      // 1.000000 (π/4)
    printf("tan(0.463648)    = %.6f\n", tan(0.463648));      // 0.500000

    // ── asin：反正弦，回傳 [-π/2, π/2] ──
    printf("asin(0.0)  = %.6f\n", asin(0.0));    // 0.000000
    printf("asin(1.0)  = %.6f\n", asin(1.0));    // 1.570796 (π/2)
    printf("asin(0.5)  = %.6f\n", asin(0.5));    // 0.523599 (π/6)

    // ── acos：反餘弦，回傳 [0, π] ──
    printf("acos(1.0)  = %.6f\n", acos(1.0));    // 0.000000
    printf("acos(0.0)  = %.6f\n", acos(0.0));    // 1.570796 (π/2)
    printf("acos(0.5)  = %.6f\n", acos(0.5));    // 1.047198 (π/3)

    // ── atan：反正切，回傳 (-π/2, π/2) ──
    printf("atan(0.0)  = %.6f\n", atan(0.0));    // 0.000000
    printf("atan(1.0)  = %.6f\n", atan(1.0));    // 0.785398 (π/4)
    printf("atan(-1.0) = %.6f\n", atan(-1.0));   // -0.785398

    // ── atan2：四象限反正切 ──
    printf("atan2(0.0, 1.0)  = %.6f\n", atan2(0.0, 1.0));    // 0.000000
    printf("atan2(1.0, 1.0)  = %.6f\n", atan2(1.0, 1.0));    // 0.785398 (π/4)
    printf("atan2(1.0, 0.0)  = %.6f\n", atan2(1.0, 0.0));    // 1.570796 (π/2)
    printf("atan2(0.0, -1.0) = %.6f\n", atan2(0.0, -1.0));   // 3.141593 (π)
    printf("atan2(-1.0,-1.0) = %.6f\n", atan2(-1.0, -1.0));  // -2.356194 (-3π/4)

    // ── sinh：雙曲正弦 ──
    printf("sinh(0.0) = %.6f\n", sinh(0.0));   // 0.000000
    printf("sinh(1.0) = %.6f\n", sinh(1.0));   // 1.175201
    printf("sinh(-1.0)= %.6f\n", sinh(-1.0));  // -1.175201

    // ── cosh：雙曲餘弦 ──
    printf("cosh(0.0) = %.6f\n", cosh(0.0));   // 1.000000
    printf("cosh(1.0) = %.6f\n", cosh(1.0));   // 1.543081
    printf("cosh(-1.0)= %.6f\n", cosh(-1.0));  // 1.543081

    // ── tanh：雙曲正切 ──
    printf("tanh(0.0) = %.6f\n", tanh(0.0));   // 0.000000
    printf("tanh(1.0) = %.6f\n", tanh(1.0));   // 0.761594
    printf("tanh(-1.0)= %.6f\n", tanh(-1.0));  // -0.761594

    // ── cbrt：立方根 ──
    printf("cbrt(0.0)   = %.6f\n", cbrt(0.0));    // 0.000000
    printf("cbrt(8.0)   = %.6f\n", cbrt(8.0));    // 2.000000
    printf("cbrt(27.0)  = %.6f\n", cbrt(27.0));   // 3.000000
    printf("cbrt(-8.0)  = %.6f\n", cbrt(-8.0));   // -2.000000

    // ── hypot：sqrt(x²+y²) ──
    printf("hypot(3.0, 4.0)  = %.6f\n", hypot(3.0, 4.0));    // 5.000000
    printf("hypot(5.0, 12.0) = %.6f\n", hypot(5.0, 12.0));   // 13.000000
    printf("hypot(0.0, 7.0)  = %.6f\n", hypot(0.0, 7.0));    // 7.000000
    printf("hypot(1.0, 1.0)  = %.6f\n", hypot(1.0, 1.0));    // 1.414214

    return 0;
}