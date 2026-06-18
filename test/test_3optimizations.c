// test_3optimizations.c
// 測試三個新功能：
//   1. 前端 DCE（if 常數條件消除）
//   2. 短路求值（&& / ||）
//   3. Strength Reduction（乘除 2 的冪次 → 位移）

int called;  // 全域計數器，測試短路求值時函式是否真的沒被呼叫

int side_effect(void) {
    called = called + 1;
    return 0;
}

int main(void) {

    // ════════════════════════════════
    // 功能 1：前端 DCE
    // ════════════════════════════════
    printf("=== DCE ===\n");

    // if(1)：else branch 完全不出現在 IR
    if (1) {
        printf("DCE: if(1) OK\n");
    } else {
        printf("DCE: DEAD - should NOT appear in IR\n");
    }

    // if(0)：true branch 完全不出現在 IR
    if (0) {
        printf("DCE: DEAD - should NOT appear in IR\n");
    } else {
        printf("DCE: if(0) else OK\n");
    }

    // 常數折疊後產生的常數條件也觸發 DCE
    // 10 > 0 → 常數折疊 → 1 → DCE
    int x;
    x = 5;
    // 純數字條件
    if (1) {
        printf("DCE: constant 1 OK\n");
    }

    // ════════════════════════════════
    // 功能 2：短路求值
    // ════════════════════════════════
    printf("=== Short-Circuit ===\n");

    // && 短路：左邊為 false 時右邊不執行
    called = 0;
    int a;
    a = 0;
    if (a && side_effect()) {
        printf("SC: WRONG\n");
    } else {
        printf("SC: && short-circuit OK\n");
    }
    printf("SC: side_effect called %d times (should be 0)\n", called);

    // || 短路：左邊為 true 時右邊不執行
    called = 0;
    int b;
    b = 1;
    if (b || side_effect()) {
        printf("SC: || short-circuit OK\n");
    } else {
        printf("SC: WRONG\n");
    }
    printf("SC: side_effect called %d times (should be 0)\n", called);

    // 短路不成立時右邊正常執行
    called = 0;
    if (a || side_effect()) {
        printf("SC: || fallthrough OK (rhs executed)\n");
    }
    printf("SC: side_effect called %d times (should be 1)\n", called);

    // ════════════════════════════════
    // 功能 3：Strength Reduction
    // ════════════════════════════════
    printf("=== Strength Reduction ===\n");

    // x * 2  → shl i32 x, 1（看 IR 檔確認）
    int n;
    n = 10;
    int r1;
    r1 = n * 2;
    printf("SR: 10 * 2 = %d\n", r1);   // 20

    // x * 4  → shl i32 x, 2
    int r2;
    r2 = n * 4;
    printf("SR: 10 * 4 = %d\n", r2);   // 40

    // x * 8  → shl i32 x, 3
    int r3;
    r3 = n * 8;
    printf("SR: 10 * 8 = %d\n", r3);   // 80

    // x / 2  → ashr i32 x, 1
    int r4;
    r4 = n / 2;
    printf("SR: 10 / 2 = %d\n", r4);   // 5

    // x / 4  → ashr i32 x, 2
    int r5;
    r5 = n / 4;
    printf("SR: 10 / 4 = %d\n", r5);   // 2

    // 非 2 的冪次：正常 mul/sdiv
    int r6;
    r6 = n * 3;
    printf("SR: 10 * 3 = %d\n", r6);   // 30 (normal mul)

    return 0;
}
