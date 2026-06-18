int factorial(int n) {
    if (n <= 1) {
        return 1;
        printf("dead in if\n");
    }
    return n * factorial(n - 1);
    printf("dead after return\n");
}

int abs_val(int x) {
    if (x >= 0) {
        return x;
        printf("dead positive\n");
    } else {
        return -x;
        printf("dead negative\n");
    }
    printf("dead after if-else\n");
    return 0;
}

int main() {
    printf("=== Pass1: Unreachable Code ===\n");
    printf("%d\n", factorial(5));
    printf("%d\n", abs_val(7));
    printf("%d\n", abs_val(-4));

    printf("=== Pass2: Dead Store ===\n");
    int x;
    x = 1;
    x = 2;
    x = 3;
    printf("%d\n", x);

    printf("=== Pass3: Dead Assignment ===\n");
    int a; a = 10;
    int b; b = 20;
    int unused; unused = a + b;
    printf("%d\n", a);

    printf("=== while + break dead ===\n");
    int i; i = 0;
    while (i < 10) {
        if (i == 3) {
            printf("found %d\n", i);
            break;
            printf("dead in break\n");
        }
        i = i + 1;
    }

    return 0;
    printf("dead after main return\n");
}
