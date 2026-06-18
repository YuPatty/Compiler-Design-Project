// test_easy_features.c
// 測試功能：assert / realloc+calloc / ctype.h / #if與#elif / sscanf / fscanf與fprintf
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// ─────────────────────────────────────────
// 測試 1：assert()
// ─────────────────────────────────────────
void test_assert() {
    printf("=== assert() ===\n");

    // 這些應該通過，程式繼續執行
    assert(1);
    assert(1 == 1);
    assert(10 > 5);

    int x = 42;
    assert(x == 42);
    assert(x > 0);

    printf("assert 全部通過\n");
}

// ─────────────────────────────────────────
// 測試 2：calloc / realloc
// ─────────────────────────────────────────
void test_calloc_realloc() {
    printf("\n=== calloc / realloc ===\n");

    // calloc：分配並初始化為 0
    int *arr = (int*)calloc(5, 4);
    printf("calloc 5 ints (預期全 0): ");
    int i;
    for (i = 0; i < 5; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");

    // 寫入值
    for (i = 0; i < 5; i++) {
        arr[i] = i * 10;
    }
    printf("填入後: ");
    for (i = 0; i < 5; i++) {
        printf("%d ", arr[i]);
    }
    printf("(預期 0 10 20 30 40)\n");

    // realloc：擴充到 8 個
    arr = (int*)realloc(arr, 32);
    arr[5] = 50;
    arr[6] = 60;
    arr[7] = 70;
    printf("realloc 後 [5~7]: %d %d %d (預期 50 60 70)\n", arr[5], arr[6], arr[7]);

    free(arr);
    printf("free 完成\n");

    // realloc(NULL, size) 相當於 malloc
    int *p = (int*)realloc(NULL, 16);
    p[0] = 999;
    printf("realloc(NULL,16): %d (預期 999)\n", p[0]);
    free(p);
}

// ─────────────────────────────────────────
// 測試 3：ctype.h 完整函式
// ─────────────────────────────────────────
void test_ctype() {
    printf("\n=== ctype.h ===\n");

    // isdigit
    printf("isdigit('5')=%d (非零) isdigit('a')=%d (0)\n",
           isdigit('5'), isdigit('a'));

    // isalpha
    printf("isalpha('A')=%d (非零) isalpha('1')=%d (0)\n",
           isalpha('A'), isalpha('1'));

    // isalnum
    printf("isalnum('z')=%d (非零) isalnum('@')=%d (0)\n",
           isalnum('z'), isalnum('@'));

    // isspace
    printf("isspace(' ')=%d (非零) isspace('x')=%d (0)\n",
           isspace(' '), isspace('x'));

    // isupper / islower
    printf("isupper('A')=%d (非零) islower('a')=%d (非零)\n",
           isupper('A'), islower('a'));

    // toupper / tolower
    int up = toupper('a');
    int lo = tolower('Z');
    printf("toupper('a')=%c (A) tolower('Z')=%c (z)\n", up, lo);

    // isxdigit（16進位字元）
    printf("isxdigit('f')=%d (非零) isxdigit('g')=%d (0)\n",
           isxdigit('f'), isxdigit('g'));

    // isprint / isgraph
    printf("isprint(' ')=%d (非零) isgraph(' ')=%d (0)\n",
           isprint(' '), isgraph(' '));

    // ispunct
    printf("ispunct('!')=%d (非零) ispunct('a')=%d (0)\n",
           ispunct('!'), ispunct('a'));

    // isblank（空白或 tab）
    printf("isblank(' ')=%d (非零) isblank('x')=%d (0)\n",
           isblank(' '), isblank('x'));

    // iscntrl（控制字元）
    printf("iscntrl(9)=%d (非零/tab) iscntrl('a')=%d (0)\n",
           iscntrl(9), iscntrl('a'));
}

// ─────────────────────────────────────────
// 測試 4：#if 與 #elif 數值條件編譯
// ─────────────────────────────────────────
#define VERSION 3
#define DEBUG 1
#define MAX_SIZE 100
#define TARGET_OS 2 // 1: Windows, 2: Linux, 3: Mac

void test_if_condition() {
    printf("\n=== #if / #elif 數值條件 ===\n");

#if VERSION >= 3
    printf("VERSION >= 3: 通過 (預期通過)\n");
#else
    printf("VERSION >= 3: 未通過 (ERROR)\n");
#endif

// 測試 #elif 命中
#if TARGET_OS == 1
    printf("作業系統: Windows (ERROR)\n");
#elif TARGET_OS == 2
    printf("作業系統: Linux (預期顯示，命中 #elif)\n");
#elif TARGET_OS == 3
    printf("作業系統: Mac (ERROR)\n");
#else
    printf("作業系統: 未知 (ERROR)\n");
#endif

#if DEBUG != 0
    printf("DEBUG 模式開啟 (預期顯示)\n");
#endif

#if MAX_SIZE > 50 && MAX_SIZE < 200
    printf("MAX_SIZE 在 50~200 之間 (預期顯示)\n");
#endif

#if defined(VERSION)
    printf("VERSION 已定義 (預期顯示)\n");
#endif

#if !defined(UNDEFINED_MACRO)
    printf("UNDEFINED_MACRO 未定義 (預期顯示)\n");
#endif

#if VERSION < 2
    printf("VERSION < 2 (ERROR，不應顯示)\n");
#endif

    printf("#if / #elif 測試完成\n");
}

// ─────────────────────────────────────────
// 測試 5：sscanf
// ─────────────────────────────────────────
void test_sscanf() {
    printf("\n=== sscanf ===\n");

    // 解析整數
    char buf1[] = "42";
    int n;
    sscanf(buf1, "%d", &n);
    printf("sscanf \"42\" → %d (預期 42)\n", n);

    // 解析浮點數
    char buf2[] = "3.14";
    double d;
    sscanf(buf2, "%lf", &d);
    printf("sscanf \"3.14\" → %.2f (預期 3.14)\n", d);

    // 解析多個值
    char buf3[] = "10 20 30";
    int a, b, c;
    sscanf(buf3, "%d %d %d", &a, &b, &c);
    printf("sscanf \"10 20 30\" → %d %d %d (預期 10 20 30)\n", a, b, c);

    // 解析字串
    char buf4[] = "Hello World";
    char word[32];
    sscanf(buf4, "%s", word);
    printf("sscanf 第一個詞 → %s (預期 Hello)\n", word);

    // 解析 long
    char buf5[] = "9876543210";
    long l;
    sscanf(buf5, "%ld", &l);
    printf("sscanf long → %ld (預期 9876543210)\n", l);
}

// ─────────────────────────────────────────
// 測試 6：fscanf 與 fprintf (檔案 I/O)
// ─────────────────────────────────────────
void test_fscanf() {
    printf("\n=== fscanf 與 fprintf ===\n");

    // 1. 建立並寫入檔案
    FILE *fp = fopen("test_io.txt", "w");
    if (fp) {
        fprintf(fp, "777 99.99 CompilerMagic\n");
        fclose(fp);
        printf("寫入 test_io.txt 成功\n");
    } else {
        printf("開啟寫入檔案失敗\n");
    }

    // 2. 讀取並解析檔案
    fp = fopen("test_io.txt", "r");
    if (fp) {
        int i_val;
        double d_val;
        char s_val[64];

        // 透過 fscanf 抓出各種型別
        fscanf(fp, "%d %lf %s", &i_val, &d_val, s_val);
        printf("fscanf 讀取整數: %d (預期 777)\n", i_val);
        printf("fscanf 讀取浮點數: %.2f (預期 99.99)\n", d_val);
        printf("fscanf 讀取字串: %s (預期 CompilerMagic)\n", s_val);

        fclose(fp);
    } else {
        printf("開啟讀取檔案失敗\n");
    }
}

// ─────────────────────────────────────────
// main
// ─────────────────────────────────────────
int main() {
    test_assert();
    test_calloc_realloc();
    test_ctype();
    test_if_condition();
    test_sscanf();
    test_fscanf();
    
    printf("\n所有測試完成\n");
    return 0;
}