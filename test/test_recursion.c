// test_recursion.c
// 測試：遞迴函式（Recursive Function）

int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int power(int base, int exp) {
    if (exp == 0) return 1;
    return base * power(base, exp - 1);
}

// 遞迴計算陣列和
int sum_array(int arr[], int n) {
    if (n <= 0) return 0;
    return arr[n - 1] + sum_array(arr, n - 1);
}

int gcd(int a, int b) {
    if (b == 0) return a;
    return gcd(b, a % b);
}

int main(void) {
    printf("=== 階乘 (Factorial) ===\n");
    printf("0! = %d\n", factorial(0));   // 1
    printf("1! = %d\n", factorial(1));   // 1
    printf("5! = %d\n", factorial(5));   // 120
    printf("10! = %d\n", factorial(10)); // 3628800

    printf("=== 費波那契 (Fibonacci) ===\n");
    int i;
    i = 0;
    while (i <= 10) {
        printf("fib(%d) = %d\n", i, fibonacci(i));
        i = i + 1;
    }

    printf("=== 次方 (Power) ===\n");
    printf("2^10 = %d\n", power(2, 10));  // 1024
    printf("3^5  = %d\n", power(3, 5));   // 243

    printf("=== 最大公因數 (GCD) ===\n");
    printf("gcd(48, 18) = %d\n", gcd(48, 18));  // 6
    printf("gcd(100, 75) = %d\n", gcd(100, 75)); // 25

    return 0;
}
