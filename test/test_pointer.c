// test_pointer.c
// 測試：指標宣告、取址、解參考、pass-by-reference、指標參數

void swap(int *a, int *b) {
    int tmp;
    tmp = *a;
    *a = *b;
    *b = tmp;
}

void double_it(int *p) {
    *p = *p * 2;
}

void negate(float *fp) {
    *fp = *fp * -1.0;
}

int main(void) {
    printf("=== 指標宣告與取址 ===\n");
    int x; x = 42;
    int *p; p = &x;
    printf("x = %d\n", x);      // 42

    printf("=== 解參考讀取 *p ===\n");
    int val; val = *p;
    printf("*p = %d\n", val);   // 42

    printf("=== 解參考賦值 *p = 100 ===\n");
    *p = 100;
    printf("x = %d\n", x);     // 100（x 被修改）
    printf("*p = %d\n", *p);   // 100

    printf("=== 宣告時直接初始化 ===\n");
    int y; y = 55;
    int *q = &y;
    printf("*q = %d\n", *q);   // 55
    *q = *q + 10;
    printf("y = %d\n", y);     // 65

    printf("=== pass-by-reference: swap ===\n");
    int a; a = 10;
    int b; b = 20;
    printf("before: a=%d b=%d\n", a, b);  // 10 20
    swap(&a, &b);
    printf("after:  a=%d b=%d\n", a, b);  // 20 10

    printf("=== double_it ===\n");
    int n; n = 7;
    printf("before: n=%d\n", n);  // 7
    double_it(&n);
    printf("after:  n=%d\n", n);  // 14

    printf("=== float 指標 ===\n");
    float f; f = 3.14;
    float *fp; fp = &f;
    printf("*fp = %f\n", *fp);   // 3.140000
    negate(fp);
    printf("f after negate = %f\n", f);  // -3.140000

    printf("=== 語意錯誤防護 ===\n");
    // 以下如果取消註解應報錯：
    //int normal_var = 5;
    //*normal_var = 10;  // Error: 'normal_var' is not a pointer
    printf("Semantic check OK\n");

    return 0;
}
