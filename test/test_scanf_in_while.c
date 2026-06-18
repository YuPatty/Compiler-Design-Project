int main(void) {
    int i, v, total;
    i = 0; total = 0;
    while (i < 3) {
        scanf("%d", &v);
        total = total + v;
        i = i + 1;
    }
    printf("total=%d\n", total);
    return 0;
}