// test_vla.c
// 測試 VLA（Variable-Length Array）：大小由執行期變數決定

int main() {
    int n;
    scanf("%d", &n);                  // 讀入陣列大小

    int arr[n];                       // VLA：大小為執行期變數 n

    // 填入 0..n-1
    int i = 0;
    while (i < n) {
        arr[i] = i * 2;
        i = i + 1;
    }

    // 印出所有元素
    int j = 0;
    while (j < n) {
        printf("arr[%d] = %d\n", j, arr[j]);
        j = j + 1;
    }

    // 計算總和
    int sum = 0;
    int k = 0;
    while (k < n) {
        sum = sum + arr[k];
        k = k + 1;
    }
    printf("sum = %d\n", sum);

    // 用運算式當 VLA 大小
    int m = n + 2;
    float fvla[m];
    int fi = 0;
    while (fi < m) {
        fvla[fi] = fi * 1.5f;
        fi = fi + 1;
    }
    printf("fvla[0] = %f\n", fvla[0]);
    printf("fvla[1] = %f\n", fvla[1]);

    return 0;
}
