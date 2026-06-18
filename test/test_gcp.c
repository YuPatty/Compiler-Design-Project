// ── 測試 3：全域常數傳播（Global Constant Propagation）──
// 驗證 GCP 能跨 basic block 把常數指派傳播到後續 load

// ── Case 1：直線流，不同 block 都使用同一常數 ──
// GCP 應把 x 的 store 42 傳播到所有後續的 load x
int test_gcp_linear() {
    int x = 42;
    int a = x + 1;    // block 1：a = 43，GCP 後變 add i32 42, 1 → peephole 折成 43
    int b = x * 2;    // block 2（after if）：b = 84
    if (a > 40) {
        printf("a = %d\n", a);  // 期望：43
    }
    printf("b = %d\n", b);     // 期望：84
    return a + b;               // 期望：127
}

// ── Case 2：常數跨 if/else 使用（單次 store，兩個 block 都讀）──
int test_gcp_if() {
    int k = 99;
    int r1, r2;
    // k 從未被修改，GCP 應在兩個 branch 都傳播 k=99
    if (k > 0) {
        r1 = k + 1;   // 期望 100
    } else {
        r1 = k - 1;   // 不走這裡
    }
    r2 = k * 2;       // 期望 198，GCP 傳播 k=99 → peephole 折疊
    printf("r1=%d r2=%d\n", r1, r2);  // 期望：100 198
    return r1 + r2;   // 298
}

// ── Case 3：常數不應傳播（迴圈內有修改）──
int test_gcp_loop() {
    int n = 5;        // GCP 不應傳播：n 在迴圈內被修改
    int sum = 0;
    int i;
    for (i = 0; i < n; i++) {
        sum += i;
    }
    printf("sum(0..4) = %d\n", sum);  // 期望：10
    return sum;
}

// ── Case 4：多常數同時傳播 ──
int test_gcp_multi() {
    int p = 3;
    int q = 7;
    int r = p + q;    // GCP: 3+7 → peephole → 10
    int s = p * q;    // GCP: 3*7 → peephole → 21
    printf("r=%d s=%d\n", r, s);  // 期望：10 21
    return r + s;     // 31
}

// ── Case 5：常數通過函式呼叫後不應繼續傳播（保守）──
int identity(int v) { return v; }
int test_gcp_call() {
    int c = 55;
    int d = identity(c);  // call → GCP 應停止對 c 傳播（c 可能被取址）
    printf("d=%d\n", d);  // 期望：55
    return d;
}

int main() {
    int r1 = test_gcp_linear();
    printf("linear ret = %d\n", r1);   // 期望：127

    int r2 = test_gcp_if();
    printf("if ret = %d\n", r2);       // 期望：298

    int r3 = test_gcp_loop();
    printf("loop ret = %d\n", r3);     // 期望：10

    int r4 = test_gcp_multi();
    printf("multi ret = %d\n", r4);    // 期望：31

    int r5 = test_gcp_call();
    printf("call ret = %d\n", r5);     // 期望：55

    return 0;
}
