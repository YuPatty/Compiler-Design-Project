// ── 測試 2：匿名 struct/union 成員（不需點號的巢狀成員存取）──

// 典型用法：struct 內含匿名 union，可直接存取 .x 或 .f
struct Variant {
    int type;
    union {
        int   x;
        float f;
    };
};

// 巢狀兩層：struct 包含匿名 union，union 內含匿名 struct
struct Complex {
    union {
        int raw;
        struct {
            short lo;
            short hi;
        };
    };
    double extra;
};

// 匿名 union 直接在 struct 最外層
struct Color {
    union {
        int packed;
        struct {
            unsigned char r;
            unsigned char g;
            unsigned char b;
            unsigned char a;
        };
    };
};

int main() {
    // ── Variant 測試 ──
    struct Variant v;
    v.type = 1;
    v.x = 42;                          // 直接存取匿名 union 的 int 成員
    printf("v.x = %d\n", v.x);        // 期望：42

    v.type = 2;
    v.f = 3.14;                        // 直接存取匿名 union 的 float 成員
    // f 與 x 共享記憶體，用 f 讀回 float
    printf("v.f > 3.0 = %d\n", v.f > 3.0);  // 期望：1

    // ── Complex 測試 ──
    struct Complex c;
    c.extra = 1.5;
    c.raw = 0x00010002;
    // lo 和 hi 透過匿名 struct 存取（不用 c.__.lo）
    printf("c.raw = %d\n", c.raw);     // 期望：65538 (0x10002)

    // ── 匿名 union 內的匿名 struct 直接存取 lo/hi ──
    // （依編譯器 endianness，lo 對應低 16 bits）
    printf("c.lo = %d\n", (int)c.lo);  // 期望：2  (低 16 bits)
    printf("c.hi = %d\n", (int)c.hi);  // 期望：1  (高 16 bits)

    // ── Color 測試 ──
    struct Color col;
    col.packed = 0xFF8040A0;  // 低位 = r，高位 = a（little-endian）
    printf("col.packed = %d\n", col.packed);

    // 直接存取匿名 struct 內的 r/g/b/a（跳過所有 . 層）
    printf("col.r = %d\n", (int)col.r);   // 期望：0xA0 = 160
    printf("col.g = %d\n", (int)col.g);   // 期望：0x40 = 64
    printf("col.b = %d\n", (int)col.b);   // 期望：0x80 = 128
    printf("col.a = %d\n", (int)col.a);   // 期望：0xFF = 255

    return 0;
}
