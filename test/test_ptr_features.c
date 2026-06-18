// test_ptr_features.c
// 驗證：指標算術 p+n、*(expr) 解參考、函式回傳指標

// ── 函式回傳指標 ──
int* get_max_ptr(int arr[], int n) {
    int *maxp;
    maxp = arr;
    int i;
    i = 1;
    while (i < n) {
        int *cur;
        cur = arr + i;
        if (*cur > *maxp) {
            maxp = cur;
        }
        i = i + 1;
    }
    return maxp;
}

int* get_at(int arr[], int idx) {
    return arr + idx;
}

int main(void) {

    // ═══════════════════════
    // 指標算術 p + n
    // ═══════════════════════
    printf("=== Pointer Arithmetic ===\n");
    int arr[5];
    arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40; arr[4] = 50;

    int *p;
    p = &arr[0];

    // p + n 得到新指標，再解參考
    int *p2;
    p2 = p + 2;
    printf("*(p+2) = %d\n", *p2);   // 30

    int *p4;
    p4 = p + 4;
    printf("*(p+4) = %d\n", *p4);   // 50

    // ═══════════════════════
    // *(expr) 解參考
    // ═══════════════════════
    printf("=== *(expr) dereference ===\n");
    printf("*(p+0) = %d\n", *(p + 0));  // 10
    printf("*(p+1) = %d\n", *(p + 1));  // 20
    printf("*(p+3) = %d\n", *(p + 3));  // 40

    // ═══════════════════════
    // *(expr) = val 賦值
    // ═══════════════════════
    printf("=== *(expr) assignment ===\n");
    *(p + 1) = 99;
    printf("arr[1] after *(p+1)=99 : %d\n", arr[1]);  // 99

    *(p + 3) = 77;
    printf("arr[3] after *(p+3)=77 : %d\n", arr[3]);  // 77

    // ═══════════════════════
    // 函式回傳指標
    // ═══════════════════════
    printf("=== Return Pointer ===\n");
    int data[5];
    data[0] = 5; data[1] = 2; data[2] = 8; data[3] = 1; data[4] = 9;

    int *ep;
    ep = get_at(data, 2);
    printf("get_at(data,2) = %d\n", *ep);   // 8

    int *mp;
    mp = get_max_ptr(data, 5);
    printf("max of data    = %d\n", *mp);    // 9

    // 透過回傳的指標修改值
    *ep = 100;
    printf("data[2] after  = %d\n", data[2]);  // 100

    *mp = 0;
    printf("max after zero = %d\n", *mp);   // 0（data[4] 被清零）
    printf("data[4]        = %d\n", data[4]); // 0

    return 0;
}
