// test_array.c
// 測試：一維陣列（含初始化清單）、二維陣列、陣列與迴圈

int main(void) {
    printf("=== 一維陣列初始化清單 ===\n");
    int arr[5] = {10, 20, 30, 40, 50};
    int i;
    i = 0;
    while (i < 5) {
        printf("arr[%d] = %d\n", i, arr[i]);  // 10 20 30 40 50
        i = i + 1;
    }

    printf("=== float 陣列初始化清單 ===\n");
    float farr[4] = {1.1, 2.2, 3.3, 4.4};
    i = 0;
    while (i < 4) {
        printf("farr[%d] = %f\n", i, farr[i]);
        i = i + 1;
    }

    printf("=== 陣列元素修改 ===\n");
    arr[2] = 999;
    printf("arr[2] = %d\n", arr[2]);  // 999

    printf("=== 陣列加總 ===\n");
    int sum;
    sum = 0; i = 0;
    while (i < 5) { sum = sum + arr[i]; i = i + 1; }
    printf("sum = %d\n", sum);  // 10+20+999+40+50 = 1119

    printf("=== 二維陣列宣告與存取 ===\n");
    int matrix[3][4];
    int r; int c;
    r = 0;
    while (r < 3) {
        c = 0;
        while (c < 4) {
            matrix[r][c] = r * 4 + c;
            c = c + 1;
        }
        r = r + 1;
    }
    printf("matrix[0][0]=%d\n", matrix[0][0]);  // 0
    printf("matrix[1][2]=%d\n", matrix[1][2]);  // 6
    printf("matrix[2][3]=%d\n", matrix[2][3]);  // 11

    printf("=== 二維陣列走訪 ===\n");
    r = 0;
    while (r < 3) {
        c = 0;
        while (c < 4) {
            printf("%3d", matrix[r][c]);
            c = c + 1;
        }
        printf("\n");
        r = r + 1;
    }

    printf("=== 陣列字串初始化清單 ===\n");
    char name[6] = "Hello";
    printf("name = %s\n", name);  // Hello

    printf("=== 字串賦值 ===\n");
    char buf[20];
    buf = "World";
    printf("buf = %s\n", buf);   // World

    return 0;
}
