// test_control_flow.c
// 測試：巢狀 if、三元運算子、while/for/do-while、switch-case、break/continue

int classify(int n) {
    if (n > 0) {
        if (n > 100) return 3;
        else if (n > 10) return 2;
        else return 1;
    } else if (n < 0) {
        return -1;
    } else {
        return 0;
    }
}

int main(void) {

    printf("=== 巢狀 if ===\n");
    printf("classify(150) = %d\n", classify(150));  // 3
    printf("classify(50)  = %d\n", classify(50));   // 2
    printf("classify(5)   = %d\n", classify(5));    // 1
    printf("classify(0)   = %d\n", classify(0));    // 0
    printf("classify(-5)  = %d\n", classify(-5));   // -1

    printf("=== 三元運算子 ===\n");
    int a; a = 10; int b; b = 20;
    int mx; mx = (a > b) ? a : b;
    printf("max(10,20) = %d\n", mx);  // 20
    int mn; mn = (a < b) ? a : b;
    printf("min(10,20) = %d\n", mn);  // 10

    // 巢狀三元
    int c; c = 15;
    int mid; mid = (a > b) ? a : ((b > c) ? b : c);
    printf("nested ternary = %d\n", mid);  // 20

    // float 三元
    float fx; fx = 3.14; float fy; fy = 2.71;
    float fmax; fmax = (fx > fy) ? fx : fy;
    printf("fmax = %f\n", fmax);  // 3.140000

    printf("=== while ===\n");
    int i; i = 0; int s; s = 0;
    while (i < 5) { s = s + i; i = i + 1; }
    printf("sum(0..4) = %d\n", s);  // 10

    printf("=== for（宣告型）===\n");
    s = 0;
    for (int j = 1; j <= 10; j++) { s = s + j; }
    printf("sum(1..10) = %d\n", s);  // 55
    // j 不外洩
    int j; j = 777;
    printf("outer j = %d\n", j);  // 777

    printf("=== do-while ===\n");
    int k; k = 0;
    do { printf("do k=%d\n", k); k = k + 1; } while (k < 3);
    // 0 1 2

    printf("=== break / continue ===\n");
    i = 0;
    while (i < 10) {
        if (i == 3) { i = i + 1; continue; }
        if (i == 6) break;
        printf("i=%d\n", i);
        i = i + 1;
    }
    // 0 1 2 4 5

    printf("=== switch-case ===\n");
    int day; day = 3;
    switch (day) {
        case 1: printf("Mon\n"); break;
        case 2: printf("Tue\n"); break;
        case 3: printf("Wed\n"); break;
        case 4: printf("Thu\n"); break;
        default: printf("Other\n"); break;
    }  // Wed

    printf("=== 巢狀迴圈 ===\n");
    for (int r = 0; r < 3; r++) {
        for (int cc = 0; cc < 3; cc++) {
            printf("%d", r * 3 + cc);
        }
        printf("\n");
    }
    // 012 / 345 / 678

    return 0;
}
