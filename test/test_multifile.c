// ════════════════════════════════════════
// 測試 2：多檔案連結（Separate Compilation）
// 這個檔案用 extern 宣告來自 math_utils.c 的函式與變數
// ════════════════════════════════════════

// ── extern 函式宣告（來自 math_utils.c）──
extern int add(int a, int b);
extern int multiply(int a, int b);
extern double power(double base, int exp);
extern void increment_counter(void);
extern int get_counter(void);

// ── extern 全域變數宣告（來自 math_utils.c）──
extern int global_counter;

int main(void) {
    // 測試 extern 函式
    int a = add(3, 4);
    printf("add(3, 4) = %d\n", a);

    int m = multiply(6, 7);
    printf("multiply(6, 7) = %d\n", m);

    double p = power(2.0, 10);
    printf("power(2.0, 10) = %.0f\n", p);

    // 測試 extern 全域變數
    increment_counter();
    increment_counter();
    increment_counter();
    int cnt = get_counter();
    printf("counter after 3 increments = %d\n", cnt);

    // 直接存取 extern 全域變數
    printf("global_counter direct = %d\n", global_counter);

    return 0;
}
