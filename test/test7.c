// test7.c
// 測試：陣列操作、巢狀迴圈 (Bubble Sort)、switch-case、函式呼叫

void printHeader() {
    printf("--- Array Sorted ---\n");
}

int main() {
    // 宣告與初始化陣列
    int arr[6];
    arr[0] = 64;
    arr[1] = 34;
    arr[2] = 25;
    arr[3] = 12;
    arr[4] = 22;
    arr[5] = 11;

    int n;
    n = 6;
    int i;
    int j;
    int temp;

    printf("Original array first element: %d\n", arr[0]);

    // 氣泡排序 (Bubble Sort) - 測試巢狀 for 迴圈與陣列讀寫
    for (i = 0; i < n - 1; i++) {
        for (j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                // 交換元素
                temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }

    printHeader();
    
    // 印出排序後的陣列
    for (i = 0; i < n; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");

    // Switch case 測試：取排序後的第一個元素 (應該是最小值 11)
    int min_val;
    min_val = arr[0];
    switch(min_val) {
        case 11:
            printf("Min value is 11, correct!\n");
            break;
        case 12:
            printf("Min value is 12, wrong!\n");
            break;
        default:
            printf("Unknown min value.\n");
            break;
    }

    return 0;
}