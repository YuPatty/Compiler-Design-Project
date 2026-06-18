// test_v6_features.c
// 測試：
//   1. static 局部變數
//   2. switch fall-through
//   3. 2D 陣列作為函式參數
//   4. __attribute__ 靜默忽略
//   5. memmove / memchr / strspn / strcspn / strpbrk

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ══════════════════════════════════════════════
// 1. static 局部變數
// ══════════════════════════════════════════════

int counter() {
    static int count = 0;
    count = count + 1;
    return count;
}

int accumulate(int n) {
    static int total = 0;
    total = total + n;
    return total;
}

void test_static() {
    printf("=== static local ===\n");
    printf("counter: %d\n", counter());   // 1
    printf("counter: %d\n", counter());   // 2
    printf("counter: %d\n", counter());   // 3

    printf("accum(10): %d\n", accumulate(10));  // 10
    printf("accum(20): %d\n", accumulate(20));  // 30
    printf("accum(5):  %d\n", accumulate(5));   // 35
}

// ══════════════════════════════════════════════
// 2. switch fall-through
// ══════════════════════════════════════════════

void test_switch_fallthrough() {
    printf("\n=== switch fall-through ===\n");

    // (A) 完整 fall-through：1 → 2 → 3
    int x = 1;
    switch (x) {
        case 1:
            printf("case1\n");
        case 2:
            printf("case2\n");
        case 3:
            printf("case3\n");
            break;
        case 4:
            printf("case4\n");
    }
    // 預期：case1 case2 case3

    // (B) 有 break 的中斷
    x = 2;
    switch (x) {
        case 1:
            printf("B-case1\n");
            break;
        case 2:
            printf("B-case2\n");
            break;
        case 3:
            printf("B-case3\n");
    }
    // 預期：B-case2

    // (C) fall-through 到 default
    x = 3;
    switch (x) {
        case 1:
            printf("C-case1\n");
        case 3:
            printf("C-case3\n");
        default:
            printf("C-default\n");
            break;
    }
    // 預期：C-case3 C-default

    // (D) 只命中 default
    x = 99;
    switch (x) {
        case 1:
            printf("D-case1\n");
            break;
        default:
            printf("D-default\n");
    }
    // 預期：D-default
}

// ══════════════════════════════════════════════
// 3. 2D 陣列作為函式參數
// ══════════════════════════════════════════════

void fill_matrix(int arr[][4], int rows) {
    int i;
    int j;
    for (i = 0; i < rows; i++) {
        for (j = 0; j < 4; j++) {
            arr[i][j] = i * 4 + j;
        }
    }
}

int sum_row(int arr[][4], int row) {
    int s = 0;
    int j;
    for (j = 0; j < 4; j++) {
        s = s + arr[row][j];
    }
    return s;
}

void print_matrix(int arr[][4], int rows) {
    int i;
    int j;
    for (i = 0; i < rows; i++) {
        for (j = 0; j < 4; j++) {
            printf("%2d ", arr[i][j]);
        }
        printf("\n");
    }
}

void test_2d_param() {
    printf("\n=== 2D array param ===\n");
    int mat[3][4];
    fill_matrix(mat, 3);
    print_matrix(mat, 3);
    // 預期：
    //  0  1  2  3
    //  4  5  6  7
    //  8  9 10 11

    printf("row0 sum = %d\n", sum_row(mat, 0));  // 6
    printf("row1 sum = %d\n", sum_row(mat, 1));  // 22
    printf("row2 sum = %d\n", sum_row(mat, 2));  // 38
}

// ══════════════════════════════════════════════
// 4. __attribute__ 靜默忽略
// ══════════════════════════════════════════════

__attribute__((unused))
int unused_var = 42;

int add_nums(int a, int b) __attribute__((pure));
int add_nums(int a, int b) {
    return a + b;
}

void test_attribute() {
    printf("\n=== __attribute__ ===\n");
    int result = add_nums(10, 20);
    printf("add(10,20) = %d\n", result);   // 30
    printf("unused_var = %d\n", unused_var); // 42
}

// ══════════════════════════════════════════════
// 5. memmove / memchr / strspn / strcspn / strpbrk
// ══════════════════════════════════════════════

void test_string_funcs() {
    printf("\n=== memmove / memchr / strspn / strcspn / strpbrk ===\n");

    // ── memmove：重疊區域安全移動 ──
    char buf[20];
    strcpy(buf, "Hello, World!");
    memmove(buf + 7, buf, 5);   // 把 "Hello" 移到第 7 位
    buf[12] = '\0';
    printf("memmove: %s\n", buf);  // Hello, Hello

    // ── memmove：非重疊 ──
    char src[16];
    char dst[16];
    strcpy(src, "ABCDE");
    memmove(dst, src, 6);
    printf("memmove dst: %s\n", dst);  // ABCDE

    // ── memchr：在記憶體中搜尋字元 ──
    char haystack[20];
    strcpy(haystack, "find the X here");
    char *found = memchr(haystack, 'X', 15);
    if (found != 0) {
        printf("memchr found 'X' at index: %d\n", (int)(found - haystack)); // 9
    } else {
        printf("memchr: not found\n");
    }

    // memchr 找不到
    char *notfound = memchr(haystack, 'Z', 15);
    printf("memchr 'Z': %s\n", (notfound == 0) ? "NULL" : "found"); // NULL

    // ── strspn：開頭連續匹配字元集的長度 ──
    char s1[32];
    strcpy(s1, "aabbccXYZ");
    int span1 = strspn(s1, "abc");
    printf("strspn(\"aabbccXYZ\",\"abc\") = %d\n", span1);  // 6

    strcpy(s1, "123hello");
    int span2 = strspn(s1, "0123456789");
    printf("strspn(\"123hello\",digits) = %d\n", span2);   // 3

    // ── strcspn：開頭連續不匹配字元集的長度 ──
    char s2[32];
    strcpy(s2, "hello world");
    int cspan1 = strcspn(s2, " ");
    printf("strcspn(\"hello world\",\" \") = %d\n", cspan1);  // 5

    strcpy(s2, "abcXYZ123");
    int cspan2 = strcspn(s2, "XYZ");
    printf("strcspn(\"abcXYZ123\",\"XYZ\") = %d\n", cspan2); // 3

    // ── strpbrk：找第一個出現在字元集中的位置 ──
    char s3[32];
    strcpy(s3, "hello world");
    char *p = strpbrk(s3, "aeiou");
    if (p != 0) {
        printf("strpbrk vowel: '%c' at %d\n", *p, (int)(p - s3)); // 'e' at 1
    }

    strcpy(s3, "no-punct-here");
    char *p2 = strpbrk(s3, "!@#$");
    printf("strpbrk punct: %s\n", (p2 == 0) ? "NULL" : "found"); // NULL
}

int main(void) {
    test_static();
    test_switch_fallthrough();
    test_2d_param();
    test_attribute();
    test_string_funcs();
    printf("\n=== 全部完成 ===\n");
    return 0;
}
