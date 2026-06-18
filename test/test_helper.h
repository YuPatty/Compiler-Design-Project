// test_helper.h：測試 #include 自訂 header 展開

#define SQUARE(x)   ((x) * (x))
#define CUBE(x)     ((x) * (x) * (x))
#define MAX2(a, b)  ((a) > (b) ? (a) : (b))

int helper_add(int a, int b) {
    return a + b;
}

int helper_factorial(int n) {
    if (n <= 1) return 1;
    return n * helper_factorial(n - 1);
}
