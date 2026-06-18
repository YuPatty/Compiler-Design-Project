// test_opt.c
int main() {
    int a;
    a = 10;

    // ── 測試 1：Frontend DCE (if 常數條件) ──
    printf("=== Test Frontend DCE ===\n");
    if (1) {
        printf("This should be generated.\n");
        a = 20;
    } else {
        printf("DEAD CODE 1: You should NOT see this in .ll\n");
        a = 999;
    }

    if (0) {
        printf("DEAD CODE 2: You should NOT see this in .ll\n");
        a = 888;
    } else {
        printf("This should also be generated.\n");
        a = 30;
    }

    // ── 測試 2：Strength Reduction (乘除 2 的冪次) ──
    printf("=== Test Strength Reduction ===\n");
    int x;
    x = 5;
    
    int mul_result;
    int div_result;
    
    mul_result = x * 8;  // 應該要變成 shl i32 ..., 3
    div_result = x / 4;  // 應該要變成 ashr i32 ..., 2
    
    printf("x * 8 = %d\n", mul_result);
    printf("x / 4 = %d\n", div_result);

    return 0;
}