// test_fileio.c
// 測試功能：fopen、fprintf、fgets、fclose（文件要求的四個函式）

int main() {
    char* fp;
    char buf[128];

    // ==========================================
    // 階段一：fopen (寫入) + fprintf
    // ==========================================
    printf("=== Stage 1: Writing with fprintf ===\n");

    fp = fopen("my_test_data.txt", "w");
    if (fp == 0) {
        printf("Error: Failed to open file for writing!\n");
        return 1;
    }

    fprintf(fp, "Line 1: Hello from fprintf!\n");
    fprintf(fp, "Line 2: Value = %d\n", 42);
    fprintf(fp, "Line 3: Pi = %f\n", 3.14159f);

    fclose(fp);
    printf("Successfully wrote 3 lines via fprintf.\n\n");

    // ==========================================
    // 階段二：fopen (讀取) + fgets
    // ==========================================
    printf("=== Stage 2: Reading with fgets ===\n");

    fp = fopen("my_test_data.txt", "r");
    if (fp == 0) {
        printf("Error: Failed to open file for reading!\n");
        return 1;
    }

    printf("--- File Content Start ---\n");
    char* line = fgets(buf, 128, fp);
    while (line != 0) {
        printf("%s", buf);
        line = fgets(buf, 128, fp);
    }
    printf("--- File Content End ---\n");

    fclose(fp);
    printf("File read and closed successfully.\n");

    return 0;
}
