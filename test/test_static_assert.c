// ── 測試 2：_Static_assert / static_assert ──

// 全域 scope：常數條件通過（不產生任何輸出或 IR）
_Static_assert(1, "This should always pass");
_Static_assert(2 + 2 == 4, "Math is broken");
_Static_assert(sizeof(int) == 4, "int must be 4 bytes");

// 全域 scope：多層條件
_Static_assert(sizeof(char) == 1, "char must be 1 byte");
_Static_assert(sizeof(double) == 8, "double must be 8 bytes");

int main() {
    // 函式內：常數條件通過
    _Static_assert(1 + 1 == 2, "Basic math failed");
    _Static_assert(sizeof(int) >= 4, "int too small");

    // 函式內：無 message 版本（C11 允許省略）
    _Static_assert(100 > 0, "Positive check");

    printf("All _Static_assert passed!\n");   // 期望：All _Static_assert passed!

    // 執行期退化：非常數條件
    int x = 42;
    _Static_assert(x > 0, "x must be positive");  // 非常數，退化為執行期 abort 防護
    printf("Runtime assert passed (x=%d)\n", x);  // 期望：Runtime assert passed (x=42)

    return 0;
}
