// test_pointer.c
// 測試指標功能：
//   1. 指標宣告與取址
//   2. 解參考讀取 *p
//   3. 解參考賦值 *p = val
//   4. 指標當函式參數（pass by reference）
//   5. 指標互指

// ── 功能 4：指標參數（模擬 pass by reference）──
void swap(int *a, int *b) {
    int tmp;
    tmp = *a;
    *a = *b;
    *b = tmp;
}

void double_val(int *p) {
    *p = *p * 2;
}

int main(void) {

    // ── 功能 1：指標宣告與取址 ──
    printf("=== 指標宣告 ===\n");
    int x;
    x = 42;
    int *p;
    p = &x;
    printf("x = %d\n", x);        // 42

    // ── 功能 2：解參考讀取 ──
    printf("=== 解參考讀取 ===\n");
    int val;
    val = *p;
    printf("*p = %d\n", val);     // 42

    // ── 功能 3：解參考賦值 ──
    printf("=== 解參考賦值 ===\n");
    *p = 100;
    printf("x after *p=100: %d\n", x);   // 100
    printf("*p = %d\n", *p);             // 100

    // ── 功能 4：指標參數 swap ──
    printf("=== swap ===\n");
    int a;
    int b;
    a = 10;
    b = 20;
    printf("before: a=%d b=%d\n", a, b);  // 10 20
    swap(&a, &b);
    printf("after:  a=%d b=%d\n", a, b);  // 20 10

    // ── 功能 4：double_val ──
    printf("=== double_val ===\n");
    int n;
    n = 7;
    printf("before: n=%d\n", n);   // 7
    double_val(&n);
    printf("after:  n=%d\n", n);   // 14

    // ── 功能 5：float 指標 ──
    printf("=== float 指標 ===\n");
    float fx;
    fx = 3.14;
    float *fp;
    fp = &fx;
    printf("*fp = %f\n", *fp);    // 3.140000
    *fp = 2.71;
    printf("fx = %f\n", fx);      // 2.710000

    // ── 指標宣告時直接初始化 ──
    printf("=== 宣告時初始化 ===\n");
    int y;
    y = 55;
    int *q = &y;
    printf("*q = %d\n", *q);      // 55
    *q = *q + 1;
    printf("y = %d\n", y);        // 56

    return 0;
}
