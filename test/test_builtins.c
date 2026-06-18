// ── 測試 3：__builtin_popcount / __builtin_clz / __builtin_ctz / __builtin_bswap ──

int main() {

    // ── popcount：計算 1 的位元個數 ──
    printf("popcount(0)   = %d\n", __builtin_popcount(0));          // 期望：0
    printf("popcount(1)   = %d\n", __builtin_popcount(1));          // 期望：1
    printf("popcount(255) = %d\n", __builtin_popcount(255));        // 期望：8
    printf("popcount(0xFF00FF) = %d\n", __builtin_popcount(0xFF00FF)); // 期望：16
    printf("popcount(-1)  = %d\n", __builtin_popcount(-1));         // 期望：32（全 1）

    // ── clz：計算前導零個數（32-bit）──
    printf("clz(1)    = %d\n", __builtin_clz(1));                   // 期望：31
    printf("clz(2)    = %d\n", __builtin_clz(2));                   // 期望：30
    printf("clz(1024) = %d\n", __builtin_clz(1024));                // 期望：21  (2^10)
    printf("clz(0x80000000) = %d\n", __builtin_clz(0x80000000));    // 期望：0

    // ── ctz：計算尾隨零個數（32-bit）──
    printf("ctz(1)    = %d\n", __builtin_ctz(1));                   // 期望：0
    printf("ctz(2)    = %d\n", __builtin_ctz(2));                   // 期望：1
    printf("ctz(16)   = %d\n", __builtin_ctz(16));                  // 期望：4   (2^4)
    printf("ctz(1024) = %d\n", __builtin_ctz(1024));                // 期望：10  (2^10)

    // ── bswap：位元組反轉 ──
    printf("bswap32(0x12345678) = %d\n", __builtin_bswap32(0x12345678)); // 期望：2018915346 (0x78563412)
    printf("bswap32(0x00000001) = %d\n", __builtin_bswap32(0x00000001)); // 期望：16777216   (0x01000000)

    // ── 64-bit 版本 ──
    printf("popcountl(0xFFFFFFFFFFFFFFFF) = %d\n",
           __builtin_popcountl(-1));                                 // 期望：64
    printf("clzl(1) = %d\n", __builtin_clzl(1));                    // 期望：63
    printf("ctzl(8) = %d\n", __builtin_ctzl(8));                    // 期望：3

    // ── 實際應用：最高有效位（floor(log2(x))）──
    int v = 100;
    int msb = 31 - __builtin_clz(v);
    printf("floor(log2(100)) = %d\n", msb);                         // 期望：6  (2^6=64 <= 100 < 128=2^7)

    // ── 實際應用：判斷是否為 2 的冪次 ──
    int p1 = 64, p2 = 100;
    printf("is_pow2(64)  = %d\n", __builtin_popcount(p1) == 1 ? 1 : 0); // 期望：1
    printf("is_pow2(100) = %d\n", __builtin_popcount(p2) == 1 ? 1 : 0); // 期望：0

    return 0;
}
