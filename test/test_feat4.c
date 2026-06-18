// test_feat4.c
// 測試：getchar/putchar、strlen/strcpy、多維陣列、const 變數

// ── 功能 4：全域 const 變數 ──
const int MAX_SIZE = 100;
const float PI = 3.14159;

// ── 功能 3：多維陣列當函式參數（用一維傳入）──
void print_matrix(int rows, int cols) {
    printf("rows=%d cols=%d\n", rows, cols);
}

int main(void) {

    // ── 功能 4：const 變數讀取 ──
    printf("MAX_SIZE = %d\n", MAX_SIZE);   // 預期: 100
    printf("PI = %f\n", PI);               // 預期: 3.141590

    // ── 功能 3：多維陣列宣告、寫入、讀取 ──
    int matrix[3][4];

    // 初始化：matrix[i][j] = i*4 + j
    int i;
    int j;
    i = 0;
    while (i < 3) {
        j = 0;
        while (j < 4) {
            matrix[i][j] = i * 4 + j;
            j = j + 1;
        }
        i = i + 1;
    }

    // 讀取幾個元素驗證
    printf("matrix[0][0] = %d\n", matrix[0][0]);  // 0
    printf("matrix[1][2] = %d\n", matrix[1][2]);  // 6
    printf("matrix[2][3] = %d\n", matrix[2][3]);  // 11

    // ── 功能 1：putchar / getchar ──
    // putchar 輸出字元
    putchar(72);   // 'H'
    putchar(105);  // 'i'
    putchar(10);   // '\n'

    // getchar 讀一個字元
    printf("Enter a char: ");
    int ch;
    ch = getchar();
    printf("You entered ASCII: %d\n", ch);

    // ── 功能 2：strlen / strcpy ──
    char src[20];
    char dst[20];

    // 先用字串初始化 src
    src[0] = 72;  // H
    src[1] = 101; // e
    src[2] = 108; // l
    src[3] = 108; // l
    src[4] = 111; // o
    src[5] = 0;   // \0

    // strlen
    int len;
    len = strlen(src);
    printf("strlen(src) = %d\n", len);  // 預期: 5

    // strcpy
    strcpy(dst, src);
    printf("strcpy dst = %s\n", dst);   // 預期: Hello

    return 0;
}
