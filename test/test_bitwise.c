// test_bitwise.c
// 測試：&、|、^、~、<<、>> 位元運算子

int main(void) {
    int a;
    int b;
    a = 0xC;   // 12
    b = 0xA;   // 10

    // 用十進位直接賦值
    a = 12;   // 1100
    b = 10;   // 1010

    printf("=== Bitwise AND (&) ===\n");
    printf("12 & 10 = %d\n", a & b);   // 1000 = 8

    printf("=== Bitwise OR (|) ===\n");
    printf("12 | 10 = %d\n", a | b);   // 1110 = 14

    printf("=== Bitwise XOR (^) ===\n");
    printf("12 ^ 10 = %d\n", a ^ b);   // 0110 = 6

    printf("=== Bitwise NOT (~) ===\n");
    // ~12 = -(12+1) = -13 (two's complement)
    int c;
    c = ~a;
    printf("~12 = %d\n", c);           // -13

    printf("=== Left Shift (<<) ===\n");
    printf("1 << 0 = %d\n", 1 << 0);   // 1
    printf("1 << 1 = %d\n", 1 << 1);   // 2
    printf("1 << 3 = %d\n", 1 << 3);   // 8
    printf("3 << 2 = %d\n", 3 << 2);   // 12

    printf("=== Right Shift (>>) ===\n");
    printf("16 >> 1 = %d\n", 16 >> 1); // 8
    printf("16 >> 2 = %d\n", 16 >> 2); // 4
    printf("15 >> 1 = %d\n", 15 >> 1); // 7

    printf("=== 複合應用：旗標位元操作 ===\n");
    int flags;
    flags = 0;
    flags = flags | 1;    // 設定 bit 0
    flags = flags | 4;    // 設定 bit 2
    printf("flags after set: %d\n", flags);    // 5
    flags = flags & ~1;   // 清除 bit 0
    printf("flags after clear: %d\n", flags);  // 4
    int bit2;
    bit2 = (flags >> 2) & 1;
    printf("bit2 = %d\n", bit2);               // 1

    return 0;
}
