// test5.c
// 測試：switch/case、array、全域變數、綜合

int globalCount;
float globalSum;

void addToSum(float val) {
    globalSum = globalSum + val;
    globalCount = globalCount + 1;
}

float getAverage() {
    if (globalCount == 0) {
        return 0.0;
    }
    return globalSum / globalCount;
}

int main() {
    globalCount = 0;
    globalSum = 0.0;

    // switch / case
    int day;
    day = 3;
    switch (day) {
        case 1:
            printf("Monday\n");
            break;
        case 2:
            printf("Tuesday\n");
            break;
        case 3:
            printf("Wednesday\n");
            break;
        case 4:
            printf("Thursday\n");
            break;
        case 5:
            printf("Friday\n");
            break;
        default:
            printf("Weekend\n");
            break;
    }

    // 陣列使用
    int arr[5];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;

    int sum;
    sum = 0;
    int k;
    for (k = 0; k < 5; k++) {
        sum = sum + arr[k];
    }
    printf("Array sum = %d\n", sum);

    // 全域變數 + 函式
    addToSum(4.5);
    addToSum(6.5);
    addToSum(8.0);
    printf("Count = %d\n", globalCount);
    printf("Average = %f\n", getAverage());

    // 巢狀迴圈（乘法表 3x3）
    int row;
    int col;
    for (row = 1; row <= 3; row++) {
        for (col = 1; col <= 3; col++) {
            printf("%d ", row * col);
        }
        printf("\n");
    }

    return 0;
}
