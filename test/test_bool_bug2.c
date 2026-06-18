int add(int a, int b) {
    return a + b;
}

int main() {
    bool flag = 5;
    int x = flag + 10;
    printf("%d\n", x);

    bool flag2 = 0;
    int y = add(flag2, 100);
    printf("%d\n", y);

    int arr[2];
    arr[0] = flag;
    printf("%d\n", arr[0]);

    bool b3 = 1;
    long lv = b3;
    printf("%ld\n", lv);

    return 0;
}
