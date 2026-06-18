// test_licm.c
// 測試 LICM（Loop-Invariant Code Motion）
// loop-invariant 的計算應該被提出到迴圈之外

int main() {
    int a = 10;
    int b = 20;
    int result = 0;
    int i = 0;

    // 迴圈中 a+b、a*2 完全不依賴 i 或 result
    // LICM 應將這兩個計算提出到 Lwhile_cond 之前
    while (i < 100) {
        int inv1 = a + b;       // loop-invariant：a、b 從未被修改
        int inv2 = a * 2;       // loop-invariant
        result = result + inv1 + inv2;
        i = i + 1;
    }
    printf("result = %d\n", result);   // (30 + 20) * 100 = 5000

    // for 迴圈版本
    int sum = 0;
    int c = 3;
    int d = 7;
    for (int j = 0; j < 50; j = j + 1) {
        int inv3 = c * d;       // loop-invariant：21
        sum = sum + inv3;
    }
    printf("sum = %d\n", sum);         // 21 * 50 = 1050

    // 確認 variant 運算不被外提（依賴 i）
    int total = 0;
    int k = 1;
    while (k <= 10) {
        int variant = k * k;    // variant：依賴 k，不應外提
        total = total + variant;
        k = k + 1;
    }
    printf("total = %d\n", total);     // 1+4+9+...+100 = 385

    return 0;
}
