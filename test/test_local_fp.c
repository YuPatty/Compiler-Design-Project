// test_local_fp.c
// 測試區域函式指標的五種情境

int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }
int mul(int a, int b) { return a * b; }
float scale(float x, float factor) { return x * factor; }
void greet(void) { printf("Hello!\n"); }
void bye(void)   { printf("Goodbye!\n"); }

// 接受函式指標為參數的高階函式
int apply(int (*f)(int, int), int x, int y) {
    return f(x, y);
}

// 回傳函式指標（透過 void* 簡化，實際測試呼叫行為）
int applyTwice(int (*f)(int, int), int x, int y) {
    return f(x, y) + f(x, y);
}

// ─────────────────────────────────────────
// 情境 1：基本宣告、初始化、呼叫
// ─────────────────────────────────────────
void test_basic() {
    int (*fp)(int, int) = add;
    int r = fp(3, 4);
    printf("basic: fp(3,4) = %d\n", r);          // 7

    fp = mul;
    r = fp(3, 4);
    printf("basic: fp(3,4) = %d\n", r);          // 12
}

// ─────────────────────────────────────────
// 情境 2：賦值後呼叫、null 初始化後賦值
// ─────────────────────────────────────────
void test_assign() {
    int (*op)(int, int);          // null 初始化
    op = sub;
    printf("assign: op(10,3) = %d\n", op(10, 3)); // 7

    op = add;
    printf("assign: op(10,3) = %d\n", op(10, 3)); // 13
}

// ─────────────────────────────────────────
// 情境 3：傳入高階函式作為參數
// ─────────────────────────────────────────
void test_higher_order() {
    int (*fp)(int, int) = add;
    int r1 = apply(fp, 5, 6);
    printf("higher: apply(add,5,6) = %d\n", r1);  // 11

    fp = mul;
    int r2 = applyTwice(fp, 5, 6);
    printf("higher: applyTwice(mul,5,6) = %d\n", r2); // 60

    // 直接傳函式名稱（函式自動轉指標）
    int r3 = apply(sub, 10, 4);
    printf("higher: apply(sub,10,4) = %d\n", r3); // 6
}

// ─────────────────────────────────────────
// 情境 4：void 函式指標
// ─────────────────────────────────────────
void test_void_fp() {
    void (*action)(void) = greet;
    action();              // Hello!
    action = bye;
    action();              // Goodbye!
}

// ─────────────────────────────────────────
// 情境 5：迴圈中動態切換函式指標
// ─────────────────────────────────────────
void test_loop_switch() {
    // 用條件判斷動態切換函式指標
    int result = 0;
    int i = 0;
    while (i < 6) {
        int (*f)(int, int);
        if (i % 3 == 0)      f = add;
        else if (i % 3 == 1) f = sub;
        else                 f = mul;
        result = result + f(i, 2);
        i = i + 1;
    }
    // i=0: add(0,2)=2, i=1: sub(1,2)=-1, i=2: mul(2,2)=4
    // i=3: add(3,2)=5, i=4: sub(4,2)=2,  i=5: mul(5,2)=10
    // total = 2-1+4+5+2+10 = 22
    printf("loop: result = %d\n", result);         // 22
}

int main() {
    test_basic();
    test_assign();
    test_higher_order();
    test_void_fp();
    test_loop_switch();
    return 0;
}