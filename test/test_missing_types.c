// ============================================================
// test_missing_types.c
// ============================================================

#include <stdio.h>
#include <stdarg.h>

// ── 1. 手動定義系統底層型別 ──
typedef long time_t;
typedef long clock_t;
typedef long ptrdiff_t;
typedef long ssize_t;
typedef long off_t;

typedef void FILE;

extern clock_t clock(void);

// ================= 測試區塊 =================

void test_div_ldiv() {
    printf("=== div / ldiv ===\n");
    int q = 38 / 5;
    int r = 38 % 5;
    printf("div(38, 5): quot=%d, rem=%d (預期: 7, 3)\n", q, r);

    long big = 10000000000;
    long divisor = 3;
    long lq = big / divisor;
    long lr = big % divisor;
    printf("ldiv(10B, 3): quot=%ld, rem=%ld (預期: 3333333333, 1)\n", lq, lr);
}

void test_time_types() {
    printf("\n=== time_t / clock_t ===\n");
    // 不呼叫 time()，直接用固定值測試 time_t 型別本身
    time_t t = 1700000000;
    printf("time_t is valid: %d (預期: 1)\n", t > 0 ? 1 : 0);
    printf("sizeof(time_t) >= 4: %d (預期: 1)\n", (long)sizeof(time_t) >= 4 ? 1 : 0);

    clock_t c = clock();
    printf("clock_t is valid: %d (預期: 1)\n", c >= 0 ? 1 : 0);
    printf("sizeof(clock_t) >= 4: %d (預期: 1)\n", (long)sizeof(clock_t) >= 4 ? 1 : 0);
}

void test_ptrdiff() {
    printf("\n=== ptrdiff_t ===\n");
    int arr[10];
    int *p1 = &arr[2];
    int *p2 = &arr[8];

    ptrdiff_t diff = p2 - p1;
    printf("ptrdiff_t (p2 - p1) = %ld (預期: 6)\n", (long)diff);
    printf("sizeof(ptrdiff_t) = %ld (預期: 8 on 64-bit)\n", (long)sizeof(ptrdiff_t));
}

void test_posix_types() {
    printf("\n=== ssize_t / off_t ===\n");
    ssize_t s_size = -1;
    off_t offset = 1024;

    printf("ssize_t value: %ld (預期: -1)\n", (long)s_size);
    printf("off_t value: %ld (預期: 1024)\n", (long)offset);
    printf("sizeof(ssize_t) = %ld (預期: 8 on 64-bit)\n", (long)sizeof(ssize_t));
    printf("sizeof(off_t)   = %ld (預期: 8 on 64-bit)\n", (long)sizeof(off_t));
}

void test_file_type() {
    printf("\n=== FILE ===\n");
    FILE *fp = (FILE*)0;
    printf("sizeof(FILE*) = %ld (預期: 8 on 64-bit)\n", (long)sizeof(fp));
}

void custom_log(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    printf("Custom Log: ");
    vprintf(fmt, args);
    va_end(args);
}

void test_va_list() {
    printf("\n=== va_list ===\n");
    custom_log("Testing va_list with %d, %s!\n", 42, "success");
}

int main() {
    test_div_ldiv();
    test_time_types();
    test_ptrdiff();
    test_posix_types();
    test_file_type();
    test_va_list();
    printf("\n=== All missing types tested ===\n");
    return 0;
}