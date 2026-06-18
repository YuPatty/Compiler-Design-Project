// test_sizeof.c
// 測試：sizeof 運算子（編譯期常數，不產生 load 指令）

int main(void) {
    printf("=== sizeof(type) ===\n");
    printf("sizeof(int)    = %d\n", sizeof(int));     // 4
    printf("sizeof(float)  = %d\n", sizeof(float));   // 4
    printf("sizeof(double) = %d\n", sizeof(double));  // 8
    printf("sizeof(char)   = %d\n", sizeof(char));    // 1

    printf("=== sizeof(expr) — 根據變數型別決定 ===\n");
    int   i;
    float f;
    char  c;
    i = 42; f = 3.14; c = 65;
    printf("sizeof(i) = %d\n", sizeof(i));  // 4
    printf("sizeof(f) = %d\n", sizeof(f));  // 4
    printf("sizeof(c) = %d\n", sizeof(c));  // 1

    printf("=== sizeof 與常數折疊結合 ===\n");
    // sizeof(int) * 10 → 4*10 → 40（全部編譯期計算）
    int total_bytes;
    total_bytes = sizeof(int) * 10;
    printf("sizeof(int)*10 = %d\n", total_bytes);  // 40

    // 動態配置大小計算
    int arr_size;
    arr_size = sizeof(float) * 5;
    printf("sizeof(float)*5 = %d\n", arr_size);    // 20

    printf("=== sizeof 在條件中 ===\n");
    if (sizeof(double) > sizeof(int)) {
        printf("double is larger than int\n");  // 應該印出
    }

    return 0;
}
