// test_operators.c
// 測試：%（取餘）、前/後置 ++/--、+=、-=、*=、/=

int main(void) {
    printf("=== %% (modulo) ===\n");
    int a;
    a = 17;
    printf("17 %% 5 = %d\n", a % 5);   // 2
    printf("10 %% 3 = %d\n", 10 % 3);  // 1
    printf("9  %% 3 = %d\n", 9 % 3);   // 0

    printf("=== prefix ++ / -- ===\n");
    int x;
    x = 5;
    printf("++x = %d\n", ++x);  // 6
    printf("x   = %d\n", x);    // 6
    printf("--x = %d\n", --x);  // 5
    printf("x   = %d\n", x);    // 5

    printf("=== postfix ++ / -- ===\n");
    int y;
    y = 10;
    printf("y++ = %d\n", y++);  // 10 (回傳舊值)
    printf("y   = %d\n", y);    // 11
    printf("y-- = %d\n", y--);  // 11 (回傳舊值)
    printf("y   = %d\n", y);    // 10

    printf("=== += ==\n");
    int n;
    n = 100;
    n += 50;
    printf("100 += 50 → %d\n", n);   // 150

    printf("=== -= ===\n");
    n -= 30;
    printf("150 -= 30 → %d\n", n);   // 120

    printf("=== *= ===\n");
    n *= 2;
    printf("120 *= 2 → %d\n", n);    // 240

    printf("=== /= ===\n");
    n /= 4;
    printf("240 /= 4 → %d\n", n);    // 60

    printf("=== %%= ===\n");
    n = 17;
    n %= 5;
    printf("17 %%= 5 → %d\n", n);    // 2

    // float compound assignment
    printf("=== float += / *= ===\n");
    float f;
    f = 1.5;
    f += 0.5;
    printf("1.5 += 0.5 → %f\n", f);  // 2.0
    f *= 3.0;
    printf("2.0 *= 3.0 → %f\n", f);  // 6.0

    return 0;
}
