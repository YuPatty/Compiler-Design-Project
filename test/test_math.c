// test_math.c
// 綜合測試：math.h 數學運算函式庫
// 測試項目：sqrt, pow, fabs, floor, fmod, ceil, sin, cos, log

#include <stdio.h>

// 註：如果你的編譯器尚未自動處理 #include <math.h> 的外部函式宣告，
// 這裡明確寫出它們的 C 語言簽名，確保編譯時能正確對接 LLVM 的 i64/double 型別。
double sqrt(double x);
double pow(double base, double exp);
double fabs(double x);
double floor(double x);
double ceil(double x);
double fmod(double x, double y);
double sin(double x);
double cos(double x);
double log(double x);

int main() {
    printf("=== 數學運算函式庫 (math.h) 測試 ===\n");

    // 1. sqrt (開根號)
    printf("sqrt(16.0) = %f (預期 4.000000)\n", sqrt(16.0));
    printf("sqrt(2.0)  = %f (預期 1.414214)\n", sqrt(2.0));

    // 2. pow (次方)
    printf("pow(2.0, 3.0) = %f (預期 8.000000)\n", pow(2.0, 3.0));
    printf("pow(5.0, 2.0) = %f (預期 25.000000)\n", pow(5.0, 2.0));

    // 3. fabs (浮點數絕對值)
    printf("fabs(-5.5) = %f (預期 5.500000)\n", fabs(-5.5));
    printf("fabs(3.14) = %f (預期 3.140000)\n", fabs(3.14));

    // 4. floor (無條件捨去)
    printf("floor(3.8)  = %f (預期 3.000000)\n", floor(3.8));
    printf("floor(-2.3) = %f (預期 -3.000000)\n", floor(-2.3));

    // 5. ceil (無條件進位)
    printf("ceil(3.2)  = %f (預期 4.000000)\n", ceil(3.2));
    printf("ceil(-2.8) = %f (預期 -2.000000)\n", ceil(-2.8));

    // 6. fmod (浮點數取餘數)
    printf("fmod(10.5, 3.0) = %f (預期 1.500000)\n", fmod(10.5, 3.0));
    printf("fmod(5.5, 2.2)  = %f (預期 1.100000)\n", fmod(5.5, 2.2));

    // 7. 三角函式 (sin, cos)
    // 使用近似值 pi = 3.14159265
    printf("sin(0.0) = %f (預期 0.000000)\n", sin(0.0));
    printf("cos(0.0) = %f (預期 1.000000)\n", cos(0.0));
    printf("sin(3.14159265 / 2.0) = %f (預期 1.000000)\n", sin(3.14159265 / 2.0));
    printf("cos(3.14159265) = %f (預期 -1.000000)\n", cos(3.14159265));

    // 8. 自然對數 (log, 底數為 e)
    // 使用近似值 e = 2.718281828
    printf("log(1.0) = %f (預期 0.000000)\n", log(1.0));
    printf("log(2.718281828) = %f (預期 1.000000)\n", log(2.718281828));

    printf("=== 所有數學測試完成 ===\n");
    return 0;
}