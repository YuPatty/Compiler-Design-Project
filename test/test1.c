// test1.c
// 測試：基本算術、比較、if-else、printf、scanf

int main() {
    int a;
    int b;
    printf("Enter two integers: ");
    scanf("%d", &a);
    scanf("%d", &b);

    int sum;
    int diff;
    int prod;
    sum = a + b;
    diff = a - b;
    prod = a * b;

    printf("Sum = %d\n", sum);
    printf("Diff = %d\n", diff);
    printf("Product = %d\n", prod);

    if (a > b) {
        printf("a is greater\n");
    } else {
        if (a == b) {
            printf("a equals b\n");
        } else {
            printf("b is greater\n");
        }
    }

    int x;
    x = 2 * (100 - 1) + a;
    printf("x = %d\n", x);

    return 0;
}