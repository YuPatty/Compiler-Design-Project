// ════════════════════════════════════════
// 測試 1：尾呼叫優化（TCO）
// ════════════════════════════════════════

// 費氏數列（非 TCO，用來對照）
int fib(int n) {
    if (n <= 1) return n;
    return fib(n - 1) + fib(n - 2);
}

// 累加（TCO 版本）：return sum(n-1, acc+n) 是尾呼叫
int sum(int n, int acc) {
    if (n == 0) return acc;
    return sum(n - 1, acc + n);
}

// 階乘（TCO 版本）
int fact(int n, int acc) {
    if (n <= 1) return acc;
    return fact(n - 1, n * acc);
}

// 計數遞減到 0（TCO）
int countdown(int n) {
    if (n == 0) return 0;
    return countdown(n - 1);
}

int main(void) {
    int s = sum(100, 0);
    printf("sum(100,0)    = %d\n", s);      // 5050

    int f = fact(10, 1);
    printf("fact(10,1)    = %d\n", f);      // 3628800

    int c = countdown(10000);
    printf("countdown(10000) = %d\n", c);   // 0

    int fb = fib(10);
    printf("fib(10)       = %d\n", fb);     // 55

    return 0;
}
