// test4.c
// 測試：函式呼叫、遞迴

int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int fibonacci(int n) {
    if (n <= 0) {
        return 0;
    }
    if (n == 1) {
        return 1;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

float average(float a, float b, float c) {
    float sum;
    sum = a + b + c;
    return sum / 3.0;
}

void printLine() {
    printf("--------------------\n");
}

int main() {
    printLine();

    // 階乘
    int i;
    for (i = 1; i <= 7; i++) {
        printf("%d! = %d\n", i, factorial(i));
    }

    printLine();

    // 費波那契
    int j;
    for (j = 0; j <= 9; j++) {
        printf("fib(%d) = %d\n", j, fibonacci(j));
    }

    printLine();

    // 平均
    float avg;
    avg = average(3.0, 5.5, 7.0);
    printf("average(3.0, 5.5, 7.0) = %f\n", avg);

    return 0;
}
