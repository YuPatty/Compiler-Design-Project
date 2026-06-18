// test_extended_types_full.c
// 終極測試：涵蓋 sizeof, signed char, long 模除, printf zext, 以及完整 stdlib
#include <stdio.h>
#include <stdlib.h>

// ─────────────────────────────────────────
// 測試 1：sizeof 與 alignOf 檢查 (Short=2, UnsignedChar=1 等)
// ─────────────────────────────────────────
void test_sizeof_rules() {
    int s_uchar = sizeof(unsigned char);   // 預期：1
    int s_schar = sizeof(signed char);     // 預期：1
    int s_short = sizeof(short);           // 預期：2
    int s_ushort = sizeof(unsigned short); // 預期：2
    int s_uint = sizeof(unsigned int);     // 預期：4
    
    printf("sizeof: uc=%d, sc=%d, sh=%d, ush=%d, ui=%d\n", 
           s_uchar, s_schar, s_short, s_ushort, s_uint);
}

// ─────────────────────────────────────────
// 測試 2：Signed Char 與 Unsigned Char 的差異
// ─────────────────────────────────────────
void test_char_variants() {
    signed char sc = -5;          // 有號，提升為 int 時應為負數
    unsigned char uc = 250;       // 無號，提升為 int 時應為正數 250
    
    int res1 = sc + 10;           // 預期：5  (需要 sext i8 to i32)
    int res2 = uc + 10;           // 預期：260(需要 zext i8 to i32)
    
    printf("char_variants: sc_res=%d, uc_res=%d\n", res1, res2);
}

// ─────────────────────────────────────────
// 測試 3：% 運算子擴充 (Long 的 srem 與 Unsigned 的 urem)
// ─────────────────────────────────────────
void test_extended_modulo() {
    long long_val = 10000000000;  // i64
    long long_res = long_val % 3; // 必須發射 srem i64

    unsigned int uint_val = 4000000000; // i32 無號
    unsigned int uint_res = uint_val % 7; // 必須發射 urem i32

    printf("extended_modulo: long_rem=%ld, uint_rem=%u\n", long_res, uint_res);
}

// ─────────────────────────────────────────
// 測試 4：printf Varargs 針對 Short 的 zext 規則
// ─────────────────────────────────────────
void test_printf_short_zext() {
    short s = 32767;
    unsigned short us = 65535;
    
    // 依照你的實作，這裡傳遞 i16 給 printf (vararg) 時，必須發射 zext i16 ... to i32
    printf("printf_short: s=%d, us=%u\n", s, us);
}

// ─────────────────────────────────────────
// 測試 5：完整 stdlib 解析與呼叫
// ─────────────────────────────────────────
void test_full_stdlib() {
    char *endptr;
    
    long l = strtol("-123456789", &endptr, 10);
    long long ll = strtoll("987654321012345", &endptr, 10);
    unsigned long ul = strtoul("4000000000", &endptr, 10);
    double d = strtod("3.14159265", &endptr);
    
    printf("stdlib_full: strtol=%ld, strtoll=%lld, strtoul=%lu, strtod=%f\n", 
           l, ll, ul, d);
}

// ─────────────────────────────────────────
// 測試 6：隱式轉型 (Short <-> Int) 與 (UnsignedInt <-> Int)
// ─────────────────────────────────────────
void test_implicit_casts() {
    int big_int = 65538;          // 0x10002
    short truncated_short = big_int; // Int -> Short 隱式轉型 (必須發射 trunc i32 to i16)
    
    unsigned int ui = 3000000000; 
    int forced_signed = ui;       // UnsignedInt -> Int 隱式轉型 (bitcast/直接當作有號)

    printf("implicit_casts: trunc_short=%d, forced_signed=%d\n", 
           truncated_short, forced_signed);
}

// ─────────────────────────────────────────
// 測試 7：labs 與 llabs 絕對值函式支援
// ─────────────────────────────────────────
void test_abs_functions() {
    // 拿掉 LL 後綴，純粹依靠編譯器後端的數值解析能力
    long l_val = -5000000000;              
    long long ll_val = -987654321012345; 
    
    long l_res = labs(l_val);
    long long ll_res = llabs(ll_val);
    
    // 預期應回傳正數
    printf("abs_functions: labs(-5000000000)=%ld, llabs(-987654321012345)=%lld\n", 
           l_res, ll_res);
}

int main() {
    test_sizeof_rules();
    test_char_variants();
    test_extended_modulo();
    test_printf_short_zext();
    test_full_stdlib();
    test_implicit_casts();
    test_abs_functions(); // 新增執行測試 7
    return 0;
}