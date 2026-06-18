// test_new_easy.c
// 測試：fread/fwrite/fseek/ftell/rewind、ferror/perror/strerror、
//        remove/rename、strdup、#字串化/##連接、getc/fputc/ungetc、%p/%zu
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ─────────────────────────────────────────
// 測試 1：fwrite / fread / fseek / ftell / rewind
// ─────────────────────────────────────────
void test_file_ops() {
    printf("=== fwrite/fread/fseek/ftell/rewind ===\n");

    FILE *fp = fopen("test_bin.dat", "w");
    if (fp == 0) { printf("fopen write failed\n"); return; }

    int data[5];
    int i;
    for (i = 0; i < 5; i++) data[i] = (i + 1) * 10;

    long written = fwrite(data, 4, 5, fp);
    printf("fwrite: wrote %ld items (預期 5)\n", written);
    fclose(fp);

    // fread
    fp = fopen("test_bin.dat", "r");
    if (fp == 0) { printf("fopen read failed\n"); return; }

    int buf[5];
    long rd = fread(buf, 4, 5, fp);
    printf("fread: read %ld items (預期 5)\n", rd);
    printf("buf[0]=%d buf[4]=%d (預期 10 50)\n", buf[0], buf[4]);

    // ftell
    long pos = ftell(fp);
    printf("ftell after fread: %ld (預期 20)\n", pos);

    // rewind
    rewind(fp);
    long pos2 = ftell(fp);
    printf("ftell after rewind: %ld (預期 0)\n", pos2);

    // fseek
    fseek(fp, 8, 0);  // SEEK_SET=0，跳到第3個int
    int val;
    fread(&val, 4, 1, fp);
    printf("fseek to byte 8, read: %d (預期 30)\n", val);

    fclose(fp);
    remove("test_bin.dat");
    printf("remove 完成\n");
}

// ─────────────────────────────────────────
// 測試 2：ferror / strerror / perror / rename / remove
// ─────────────────────────────────────────
void test_error_ops() {
    printf("\n=== ferror/strerror/perror/rename/remove ===\n");

    // strerror
    char *msg = strerror(2);  // ENOENT
    printf("strerror(2) = %s\n", msg);

    // ferror（開啟成功的檔案 error 應為 0）
    FILE *fp = fopen("test_rename_src.txt", "w");
    if (fp == 0) { printf("fopen failed\n"); return; }
    fprintf(fp, "rename test\n");
    fclose(fp);

    fp = fopen("test_rename_src.txt", "r");
    int err = ferror(fp);
    printf("ferror on good file: %d (預期 0)\n", err);
    fclose(fp);

    // rename
    int rr = rename("test_rename_src.txt", "test_rename_dst.txt");
    printf("rename result: %d (預期 0)\n", rr);

    // 確認改名後可開啟
    fp = fopen("test_rename_dst.txt", "r");
    if (fp != 0) {
        printf("renamed file opened OK\n");
        fclose(fp);
    }

    // remove
    int rv = remove("test_rename_dst.txt");
    printf("remove result: %d (預期 0)\n", rv);

    // perror（只要不崩潰就好）
    perror("test perror");
    printf("perror 完成\n");
}

// ─────────────────────────────────────────
// 測試 3：strdup
// ─────────────────────────────────────────
void test_strdup() {
    printf("\n=== strdup ===\n");

    char *orig = "Hello, World!";
    char *dup = strdup(orig);
    printf("strdup: %s\n", dup);
    printf("strcmp: %d (預期 0)\n", strcmp(orig, dup));
    printf("same ptr: %d (預期 0, 不同位址)\n", orig == dup);
    free(dup);
    printf("free(dup) 完成\n");
}

// ─────────────────────────────────────────
// 測試 4：# 字串化 / ## token 連接
// ─────────────────────────────────────────
#define STRINGIFY(x) #x
#define CONCAT(a, b) a##b
#define MAKE_VAR(name) int my_##name

void test_preprocessor_ops() {
    printf("\n=== # stringification / ## concatenation ===\n");

    // # 字串化
    char *s1 = STRINGIFY(hello);
    printf("STRINGIFY(hello) = %s (預期 hello)\n", s1);

    char *s2 = STRINGIFY(42);
    printf("STRINGIFY(42) = %s (預期 42)\n", s2);

    // ## 連接
    int CONCAT(my_, val) = 999;
    printf("CONCAT(my_,val) = %d (預期 999)\n", my_val);

    MAKE_VAR(score) = 100;
    printf("MAKE_VAR(score) = %d (預期 100)\n", my_score);
}

// ─────────────────────────────────────────
// 測試 5：getc / fputc / ungetc
// ─────────────────────────────────────────
void test_char_io() {
    printf("\n=== getc/fputc/ungetc ===\n");

    // fputc 寫入
    FILE *fp = fopen("test_char.txt", "w");
    if (fp == 0) { printf("fopen failed\n"); return; }
    fputc('A', fp);
    fputc('B', fp);
    fputc('C', fp);
    fputc('\n', fp);
    fclose(fp);

    // getc 讀取
    fp = fopen("test_char.txt", "r");
    if (fp == 0) { printf("fopen failed\n"); return; }

    int c1 = getc(fp);
    int c2 = getc(fp);
    int c3 = getc(fp);
    printf("getc: %c %c %c (預期 A B C)\n", c1, c2, c3);

    // ungetc：把字元推回
    ungetc(c3, fp);
    int c3again = getc(fp);
    printf("ungetc then getc: %c (預期 C)\n", c3again);

    fclose(fp);
    remove("test_char.txt");
    printf("char I/O 完成\n");
}

// ─────────────────────────────────────────
// 測試 6：%p / %zu 格式
// ─────────────────────────────────────────
void test_format_specifiers() {
    printf("\n=== %%p / %%zu format ===\n");

    int x = 42;
    int *px = &x;
    printf("pointer %%p: %p (非 null 即可)\n", px);

    // %zu size_t
    int arr[10];
    long sz = 10;
    printf("size %%zu: %zu (預期 10)\n", sz);

    // NULL pointer
    int *np = 0;
    printf("null ptr %%p: %p\n", np);
}

// ─────────────────────────────────────────
// main
// ─────────────────────────────────────────
int main() {
    test_file_ops();
    test_error_ops();
    test_strdup();
    test_preprocessor_ops();
    test_char_io();
    test_format_specifiers();
    printf("\n=== 所有測試完成 ===\n");
    return 0;
}
