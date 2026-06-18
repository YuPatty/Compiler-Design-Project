// test_global_fp.c
// 測試全域函式指標：宣告、初始化、呼叫、重新賦值

int add(int x, int y) {
    return x + y;
}

int mul(int x, int y) {
    return x * y;
}

int sub(int x, int y) {
    return x - y;
}

// 全域函式指標：宣告時初始化為 add
int (*op)(int, int) = add;

// 全域函式指標：初始為 null，稍後賦值
int (*op2)(int, int);

// 無參數、void 回傳的全域函式指標
void (*logger)(void);

void greet() {
    printf("Hello from greet!\n");
}

void bye() {
    printf("Goodbye!\n");
}

int applyTwice(int (*f)(int, int), int a, int b) {
    return f(a, b) + f(a, b);
}

int main() {
    // 透過全域函式指標呼叫 add
    int r1 = op(3, 4);
    printf("op(3,4) = %d\n", r1);        // 7

    // 重新賦值為 mul
    op = mul;
    int r2 = op(3, 4);
    printf("op(3,4) = %d\n", r2);        // 12

    // op2 初始為 null，賦值後呼叫
    op2 = sub;
    int r3 = op2(10, 3);
    printf("op2(10,3) = %d\n", r3);      // 7

    // void 函式指標
    logger = greet;
    logger();                             // Hello from greet!
    logger = bye;
    logger();                             // Goodbye!

    // 把全域函式指標傳給函式
    op = add;
    int r4 = applyTwice(op, 5, 6);
    printf("applyTwice(add,5,6) = %d\n", r4);  // (5+6)*2 = 22

    op = mul;
    int r5 = applyTwice(op, 5, 6);
    printf("applyTwice(mul,5,6) = %d\n", r5);  // (5*6)*2 = 60

    return 0;
}
