// test_long.c
// 測試 long / long long 型別：宣告、算術（+-*/）、比較、printf %ld

int main() {
    long a = 1000000000;
    long b = 3000000000;

    // ── 加法 ──
    long c = a + b;
    printf("a = %ld\n", a);
    printf("b = %ld\n", b);
    printf("a + b = %ld\n", c);

    // ── 減法 ──
    long d = b - a;
    printf("b - a = %ld\n", d);

    // ── 乘法 ──
    long e = a * 2;
    printf("a * 2 = %ld\n", e);

    // ── 除法 ──
    long f = b / 3;
    printf("b / 3 = %ld\n", f);

    // ── long long ──
    long long x = 9000000000;
    long long y = 1000000000;
    long long z = x + y;
    printf("x = %ld\n", x);
    printf("x + y = %ld\n", z);

    // ── 比較 ──
    if (c > 3000000000) {
        printf("c > 3000000000: true\n");
    } else {
        printf("c > 3000000000: false\n");
    }

    // ── 迴圈 ──
    long sum = 0;
    long i = 0;
    while (i < 5) {
        sum = sum + i;
        i = i + 1;
    }
    printf("sum 0..4 = %ld\n", sum);

    return 0;
}
