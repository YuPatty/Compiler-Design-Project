// test_prototype.c
// 測試：前置宣告（Prototype）
// 函式在使用之前只宣告簽名，實際定義在後面

// ── 前置宣告（沒有 body，只有分號）──
int add(int a, int b);
float circle_area(float r);
void print_banner(int n);
int fibonacci(int n);

int main(void) {
    // 使用在後面才定義的函式
    printf("=== Prototype Test ===\n");

    int s;
    s = add(3, 4);
    printf("add(3,4) = %d\n", s);           // 7

    float area;
    area = circle_area(5.0);
    printf("circle_area(5.0) = %f\n", area); // 78.539750

    print_banner(3);

    printf("fib(10) = %d\n", fibonacci(10)); // 55

    return 0;
}

// ── 函式實際定義（在 main 之後）──
int add(int a, int b) {
    return a + b;
}

float circle_area(float r) {
    float pi;
    pi = 3.14159;
    return pi * r * r;
}

void print_banner(int n) {
    int i;
    i = 0;
    while (i < n) {
        printf("*** Banner line %d ***\n", i + 1);
        i = i + 1;
    }
}

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
