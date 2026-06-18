// test_batch1.c
// 測試第一批新功能：
//   clearerr / tmpfile / tmpnam / popen / pclose / setvbuf / setbuf
//   modf / frexp / ldexp / scalbn / ilogb
//   signal / raise
//   vprintf / vfprintf / vsprintf / vsnprintf
//   __builtin_expect / for 多變數宣告
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <signal.h>
#include <stdarg.h>

#pragma once
#pragma GCC optimize("O2")

// ── 測試 1：clearerr ──
void test_clearerr() {
    printf("=== clearerr ===\n");
    FILE *fp = fopen("test_clearerr.txt", "w");
    fprintf(fp, "hello\n");
    fclose(fp);

    fp = fopen("test_clearerr.txt", "r");
    // 讀到底讓 EOF 設定
    char buf[64];
    while (fgets(buf, 64, fp) != NULL) {}
    int eof_before = feof(fp);
    clearerr(fp);
    int eof_after = feof(fp);
    printf("feof before clearerr: %d (非零)\n", eof_before);
    printf("feof after  clearerr: %d (預期 0)\n", eof_after);
    fclose(fp);
    remove("test_clearerr.txt");
}

// ── 測試 2：tmpfile / tmpnam ──
void test_tmp() {
    printf("\n=== tmpfile / tmpnam ===\n");
    FILE *tf = tmpfile();
    if (tf != NULL) {
        fprintf(tf, "tmp content\n");
        rewind(tf);
        char buf[64];
        fgets(buf, 64, tf);
        printf("tmpfile read: %s", buf);  // "tmp content\n"
        fclose(tf);
    } else {
        printf("tmpfile() returned NULL\n");
    }

    char namebuf[256];
    char *tname = tmpnam(namebuf);
    printf("tmpnam: %s (非空字串)\n", tname ? "(ok)" : "(NULL)");
}

// ── 測試 3：popen / pclose ──
void test_popen() {
    printf("\n=== popen / pclose ===\n");
    FILE *pipe = popen("echo popen_test_ok", "r");
    if (pipe != NULL) {
        char buf[128];
        fgets(buf, 128, pipe);
        // 去掉尾端換行
        int len = strlen(buf);
        if (len > 0 && buf[len-1] == '\n') buf[len-1] = '\0';
        printf("popen read: %s (預期 popen_test_ok)\n", buf);
        int rc = pclose(pipe);
        printf("pclose: %d (預期 0)\n", rc);
    } else {
        printf("popen failed\n");
    }
}

// ── 測試 4：setvbuf / setbuf ──
void test_setvbuf() {
    printf("\n=== setvbuf / setbuf ===\n");
    FILE *fp = fopen("test_setvbuf.txt", "w");
    // 設定無緩衝 (_IONBF=2)
    int r = setvbuf(fp, NULL, 2, 0);
    printf("setvbuf(_IONBF) result: %d (預期 0)\n", r);
    fprintf(fp, "setvbuf test\n");
    fclose(fp);
    remove("test_setvbuf.txt");

    fp = fopen("test_setvbuf2.txt", "w");
    setbuf(fp, NULL);  // 設定無緩衝
    fprintf(fp, "setbuf test\n");
    fclose(fp);
    remove("test_setvbuf2.txt");
    printf("setbuf: 完成\n");
}

// ── 測試 5：modf / frexp / ldexp / scalbn / ilogb ──
void test_math_funcs() {
    printf("\n=== modf / frexp / ldexp / scalbn / ilogb ===\n");

    double intpart;
    double frac = modf(3.75, &intpart);
    printf("modf(3.75): frac=%.2f intpart=%.2f (預期 0.75 3.00)\n", frac, intpart);

    double neg_frac = modf(-2.5, &intpart);
    printf("modf(-2.5): frac=%.2f intpart=%.2f (預期 -0.50 -2.00)\n", neg_frac, intpart);

    int exp_val;
    double mantissa = frexp(8.0, &exp_val);
    printf("frexp(8.0): mantissa=%.4f exp=%d (預期 0.5000 4)\n", mantissa, exp_val);

    double ldexp_result = ldexp(0.5, 4);
    printf("ldexp(0.5, 4) = %.1f (預期 8.0)\n", ldexp_result);

    double scalbn_result = scalbn(1.0, 10);
    printf("scalbn(1.0, 10) = %.1f (預期 1024.0)\n", scalbn_result);

    int ilogb_result = ilogb(1024.0);
    printf("ilogb(1024.0) = %d (預期 10)\n", ilogb_result);
}

// ── 測試 6：signal / raise ──
volatile int signal_received = 0;

void my_handler(int sig) {
    signal_received = sig;
}

void test_signal() {
    printf("\n=== signal / raise ===\n");
    signal(2, my_handler);  // SIGINT = 2
    raise(2);
    printf("signal_received = %d (預期 2)\n", signal_received);
    // 還原預設
    signal(2, (void*)0);    // SIG_DFL = 0
}

// ── 測試 7：vprintf / vsprintf / vsnprintf ──
int my_printf(const char *fmt, ...) {
    char buf[256];
    // 使用 vsprintf 模擬（因為 va_list 傳遞在本 compiler 用 i8*）
    va_list ap;
    va_start(ap, fmt);
    int n = vsprintf(buf, fmt, ap);
    va_end(ap);
    printf("%s", buf);
    return n;
}

int my_snprintf(char *out, int maxn, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(out, maxn, fmt, ap);
    va_end(ap);
    return n;
}

void test_vprintf() {
    printf("\n=== vsprintf / vsnprintf ===\n");
    int n = my_printf("my_printf: %d + %d = %d\n", 3, 4, 7);
    printf("my_printf returned: %d (預期 > 0)\n", n > 0);

    char snbuf[16];
    int sn = my_snprintf(snbuf, 8, "Hello, World!");
    printf("vsnprintf truncated: %s (預期 Hello, )\n", snbuf);
    printf("vsnprintf returned:  %d (預期 13, 原始長度)\n", sn);
}

// ── 測試 8：for 多變數宣告 ──
void test_for_multi_var() {
    printf("\n=== for 多變數宣告 ===\n");
    int sum = 0;
    for (int i = 0, j = 10; i < 5; i++, j--) {
        sum += i + j;
    }
    // i=0,j=10: 10; i=1,j=9: 10; i=2,j=8: 10; i=3,j=7: 10; i=4,j=6: 10 → sum=50
    printf("for(int i=0,j=10;i<5;i++,j--) sum of i+j = %d (預期 50)\n", sum);

    // 多型別（同一型別多變數）
    int a = 0, b = 0;
    for (int x = 1, y = 100; x <= 3; x++, y -= 30) {
        a += x; b += y;
    }
    printf("x sum=%d (預期 6), y sum=%d (預期 210)\n", a, b);
}

// ── 測試 9：__builtin_expect ──
void test_builtin_expect() {
    printf("\n=== __builtin_expect ===\n");
    int x = 42;
    if (__builtin_expect(x == 42, 1)) {
        printf("__builtin_expect(true) branch taken (預期)\n");
    }
    if (!__builtin_expect(x == 0, 0)) {
        printf("__builtin_expect(false) branch skipped (預期)\n");
    }
}

int main() {
    test_clearerr();
    test_tmp();
    test_popen();
    test_setvbuf();
    test_math_funcs();
    test_signal();
    test_vprintf();
    test_for_multi_var();
    test_builtin_expect();
    printf("\n=== 所有測試完成 ===\n");
    return 0;
}
