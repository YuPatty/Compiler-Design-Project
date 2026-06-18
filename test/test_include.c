// ── 測試 1：#include 自訂 header ──
#include "test_helper.h"

int main() {
    // 使用 header 裡定義的巨集
    int s = SQUARE(5);
    printf("SQUARE(5) = %d\n", s);           // 期望：25

    int c = CUBE(3);
    printf("CUBE(3) = %d\n", c);             // 期望：27

    int m = MAX2(10, 20);
    printf("MAX2(10,20) = %d\n", m);         // 期望：20

    // 使用 header 裡定義的函式
    int sum = helper_add(7, 8);
    printf("helper_add(7,8) = %d\n", sum);   // 期望：15

    int fact = helper_factorial(6);
    printf("factorial(6) = %d\n", fact);     // 期望：720

    return 0;
}
