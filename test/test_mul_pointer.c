int main() {
    int x;
    x = 42;

    int* p;
    p = &x;
    printf("%d\n", *p);      // 42

    int** pp;
    pp = &p;
    printf("%d\n", **pp);    // 42

    **pp = 99;
    printf("%d\n", x);       // 99

    int* q;
    q = *pp;
    printf("%d\n", *q);      // 99

    return 0;
}