// test_peephole.c
// 測試 Peephole Optimization 的各種化簡模式
// 每個函式對應一組 pattern，預期 IR 中不應出現被化簡掉的指令

// ─────────────────────────────────────────
// P1/P2：整數加零、減零消除
// a + 0 → a,  a - 0 → a
// ─────────────────────────────────────────
void test_add_sub_zero() {
    int a = 42;
    int r1 = a + 0;    // → 直接用 a，不發 add
    int r2 = a - 0;    // → 直接用 a，不發 sub
    int r3 = 0 + a;    // → 直接用 a
    printf("add_sub_zero: %d %d %d\n", r1, r2, r3);  // 42 42 42
}

// ─────────────────────────────────────────
// P3/P4/P5：乘零、乘一、除一消除
// ─────────────────────────────────────────
void test_mul_div_identity() {
    int a = 7;
    int r1 = a * 0;    // → 0
    int r2 = a * 1;    // → a
    int r3 = a / 1;    // → a
    int r4 = 0 * a;    // → 0
    printf("mul_div_id: %d %d %d %d\n", r1, r2, r3, r4);  // 0 7 7 0
}

// ─────────────────────────────────────────
// P6/P7/P8/P9：乘除 2 的冪次 → 位移
// x*2 → shl 1,  x/2 → ashr 1
// x*4 → shl 2,  x/4 → ashr 2
// x*8 → shl 3,  x/8 → ashr 3
// ─────────────────────────────────────────
void test_strength_shift() {
    int x = 16;
    int r1 = x * 2;    // → shl i32 %x, 1  = 32
    int r2 = x / 2;    // → ashr i32 %x, 1 = 8
    int r3 = x * 4;    // → shl i32 %x, 2  = 64
    int r4 = x / 4;    // → ashr i32 %x, 2 = 4
    int r5 = x * 8;    // → shl i32 %x, 3  = 128
    int r6 = x / 8;    // → ashr i32 %x, 3 = 2
    printf("shift: %d %d %d %d %d %d\n", r1, r2, r3, r4, r5, r6);
    // 32 8 64 4 128 2
}

// ─────────────────────────────────────────
// P10/P11/P12：浮點加零、減零、乘一消除
// ─────────────────────────────────────────
void test_float_identity() {
    float f = 3.5f;
    float r1 = f + 0.0f;   // → f
    float r2 = f - 0.0f;   // → f
    float r3 = f * 1.0f;   // → f
    float r4 = 0.0f + f;   // → f
    float r5 = 1.0f * f;   // → f
    printf("float_id: %f %f %f %f %f\n", r1, r2, r3, r4, r5);
    // 3.500000 x5
}

// ─────────────────────────────────────────
// P16/P17：常數條件分支化簡
// if (1) / if (0) 在 constant folding 後產生 br i1 true/false
// Peephole 再把它化簡為無條件 br
// ─────────────────────────────────────────
void test_const_branch() {
    int x = 10;
    // 1 != 0 → constant folding → true → br i1 true → br label %then
    if (1) {
        x = x + 1;
    } else {
        x = x - 1;    // dead code
    }
    // 0 != 0 → false → br label %else
    if (0) {
        x = x + 100;  // dead code
    } else {
        x = x + 2;
    }
    printf("const_branch: %d\n", x);  // 10+1+2 = 13
}

// ─────────────────────────────────────────
// P18/P19/P21：移位零、or 零、xor 零消除
// ─────────────────────────────────────────
void test_bitwise_identity() {
    int a = 0xFF;
    int r1 = a | 0;     // → a = 255
    int r2 = a ^ 0;     // → a = 255
    printf("bitwise_id: %d %d\n", r1, r2);  // 255 255
}

// ─────────────────────────────────────────
// 綜合：連鎖化簡（多個 pattern 疊加）
// ─────────────────────────────────────────
void test_chain() {
    int a = 5;
    // (a * 1 + 0) * 4 - 0
    // = a * 4            （乘一、加零、減零消除）
    // = shl a, 2         （乘 4 轉移位）
    int r = (a * 1 + 0) * 4 - 0;
    printf("chain: %d\n", r);  // 20
}

int main() {
    test_add_sub_zero();
    test_mul_div_identity();
    test_strength_shift();
    test_float_identity();
    test_const_branch();
    test_bitwise_identity();
    test_chain();
    return 0;
}
