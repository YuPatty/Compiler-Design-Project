// test_new_features_fixed.c
// 測試四個新功能：強度削減、__LINE__/__FILE__/__func__、stdint.h、string 函式擴充
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// ─────────────────────────────────────────
// 測試 1：強度削減（Strength Reduction）
// ─────────────────────────────────────────
void test_strength_reduction() {
    printf("=== Strength Reduction ===\n");
    int x = 7;
    int r1 = x * 1;   printf("7*1=%d (預期7)\n", r1);
    int r2 = x / 1;   printf("7/1=%d (預期7)\n", r2);
    int r3 = x * 0;   printf("7*0=%d (預期0)\n", r3);
    int r4 = 0 * x;   printf("0*7=%d (預期0)\n", r4);
    int r5 = x * 2;   printf("7*2=%d (預期14)\n", r5);
    int r6 = x * 4;   printf("7*4=%d (預期28)\n", r6);
    int r7 = x * 8;   printf("7*8=%d (預期56)\n", r7);
    int r8 = 2 * x;   printf("2*7=%d (預期14)\n", r8);
    int r9 = x / 2;   printf("7/2=%d (預期3)\n", r9);
    int r10 = x / 4;  printf("7/4=%d (預期1)\n", r10);
    int r11 = x / 8;  printf("7/8=%d (預期0)\n", r11);
    long lx = 100;
    long lr1 = lx * 8;
    long lr2 = lx / 4;
    long lr3 = lx * 1;
    long lr4 = lx * 0;
    printf("long: 100*8=%ld 100/4=%ld 100*1=%ld 100*0=%ld\n", lr1, lr2, lr3, lr4);
    printf("預期: 800 25 100 0\n");
}

// ─────────────────────────────────────────
// 測試 2：__LINE__ / __FILE__ / __func__
// ─────────────────────────────────────────
#define LOG(msg) printf("[%s:%d] %s\n", __func__, __LINE__, msg)

void helper_func() {
    // 直接用 printf %s 傳 __func__
    printf("helper called: %s\n", __func__);
}

void test_builtin_macros() {
    printf("\n=== Built-in Macros ===\n");
    int myLine = __LINE__;
    printf("myLine=%d (非零正整數)\n", myLine);
    printf("file=%s\n", __FILE__);
    printf("func=%s (預期 test_builtin_macros)\n", __func__);
    helper_func();
    LOG("hello from LOG macro");
    LOG("second log");
}

// ─────────────────────────────────────────
// 測試 3：stdint.h 固定寬度型別
// ─────────────────────────────────────────
void test_stdint() {
    printf("\n=== stdint.h Types ===\n");
    int8_t   a = -128;
    uint8_t  b = 255;
    int16_t  c = -32768;
    uint16_t d = 65535;
    int32_t  e = -2147483648;
    uint32_t f = 4294967295;
    int64_t  g = -9223372036854775807;
    printf("int8_t   min=%d (預期-128)\n", a);
    printf("uint8_t  max=%u (預期255)\n", b);
    printf("int16_t  min=%d (預期-32768)\n", c);
    printf("uint16_t max=%u (預期65535)\n", d);
    printf("int32_t  min=%d (預期-2147483648)\n", e);
    printf("uint32_t max=%u (預期4294967295)\n", f);
    printf("int64_t  min=%lld\n", g);
    size_t sz = 1024;
    sz = sz * 2;
    printf("size_t 1024*2=%lu (預期2048)\n", sz);
    int32_t x32 = 42;
    int64_t x64 = x32;
    printf("int32->int64: %lld (預期42)\n", x64);
}

// ─────────────────────────────────────────
// 測試 4：string.h 擴充函式
// ─────────────────────────────────────────
void test_string_funcs() {
    printf("\n=== String Functions ===\n");
    char dst[64];
    strncpy(dst, "Hello, World!", 5);
    dst[5] = '\0';
    printf("strncpy 5 chars: \"%s\" (預期Hello)\n", dst);

    char buf[64];
    strcpy(buf, "Hello");
    strncat(buf, ", World!", 7);
    printf("strncat 7: \"%s\" (預期Hello, World)\n", buf);

    int cmp1 = strncmp("abcdef", "abcxyz", 3);
    int cmp2 = strncmp("abcdef", "abcxyz", 6);
    printf("strncmp 3: %d (預期0)\n", cmp1);
    printf("strncmp 6: %d (預期<0)\n", cmp2);

    char haystack[] = "The quick brown fox";
    char *found = strstr(haystack, "brown");
    if (found) printf("strstr found: \"%s\"\n", found);
    else       printf("strstr: not found (ERROR)\n");

    char *p1 = strchr("Hello", 108);
    printf("strchr 'l': %s (預期llo)\n", p1);

    char *p2 = strrchr("Hello", 108);
    printf("strrchr 'l': %s (預期lo)\n", p2);

    char tokens[] = "one,two,three";
    char *tok = strtok(tokens, ",");
    printf("strtok: ");
    while (tok != NULL) {
        printf("%s ", tok);
        tok = strtok(NULL, ",");
    }
    printf("(預期 one two three)\n");
}

int main() {
    test_strength_reduction();
    test_builtin_macros();
    test_stdint();
    test_string_funcs();
    return 0;
}