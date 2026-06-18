// ============================================================
// test_int_div.c
// 測試 C99 標準下的有號整數除法 (sdiv) 與取餘數 (srem)
// ============================================================
#include <stdio.h>

int test_div(int a, int b) {
    return a / b;
}

int test_mod(int a, int b) {
    return a % b;
}

int main(void) {
    printf("=== Constant Folding Test ===\n");
    // 測試前端 AST 的運算邏輯是否正確 (常數折疊)
    int c1 = 5 / 2;
    int c2 = -3 / 2;
    int c3 = -7 / 2;
    int c4 = -5 / 2;
    int c5 = -1 / 2;
    int c6 = (3 - 8) / 2;
    int c7 = (-10 - 5) / 2;
    int c8 = -8 / 4;

    printf("5 / 2 = %d\n", c1);
    printf("-3 / 2 = %d\n", c2);
    printf("-7 / 2 = %d\n", c3);
    printf("-5 / 2 = %d\n", c4);
    printf("-1 / 2 = %d\n", c5);
    printf("(3-8) / 2 = %d\n", c6);
    printf("(-10-5) / 2 = %d\n", c7);
    printf("-8 / 4 = %d\n", c8);

    printf("=== Runtime Division (sdiv) Test ===\n");
    // 測試後端 LLVM IR 發射的指令執行結果
    printf("5 / 2 = %d\n", test_div(5, 2));
    printf("-3 / 2 = %d\n", test_div(-3, 2));
    printf("-7 / 2 = %d\n", test_div(-7, 2));
    printf("-5 / 2 = %d\n", test_div(-5, 2));
    printf("-1 / 2 = %d\n", test_div(-1, 2));
    printf("(3-8) / 2 = %d\n", test_div(3 - 8, 2));
    printf("(-10-5) / 2 = %d\n", test_div(-10 - 5, 2));
    printf("-8 / 4 = %d\n", test_div(-8, 4));
    printf("7 / -3 = %d\n", test_div(7, -3));
    printf("-10 / -3 = %d\n", test_div(-10, -3));

    printf("=== Runtime Modulo (srem) Test ===\n");
    // 餘數的符號必須與被除數相同
    printf("5 %% 2 = %d\n", test_mod(5, 2));
    printf("-3 %% 2 = %d\n", test_mod(-3, 2));
    printf("7 %% -3 = %d\n", test_mod(7, -3));
    printf("-10 %% -3 = %d\n", test_mod(-10, -3));

    return 0;
}