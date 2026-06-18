// test_argc_funcptr.c
// 驗證：1. argc/argv 命令列參數  2. 函式指標宣告、賦值、呼叫

// ── 供函式指標測試用的函式 ──
int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }
int mul(int a, int b) { return a * b; }
int max2(int a, int b) { return (a > b) ? a : b; }

// ── 接受函式指標為參數 ──
int apply(int (*op)(int, int), int x, int y) {
    return op(x, y);
}

// ── 函式指標在分支中切換 ──
int dispatch(int choice, int a, int b) {
    int (*fp)(int, int) = add;
    if (choice == 1) fp = sub;
    if (choice == 2) fp = mul;
    return fp(a, b);
}

int main(int argc, char *argv[]) {

    // ════════════════════
    // 1. argc / argv
    // ════════════════════
    printf("=== argc / argv ===\n");
    printf("argc = %d\n", argc);
    int i;
    i = 0;
    while (i < argc) {
        printf("argv[%d] = %s\n", i, argv[i]);
        i = i + 1;
    }

    // ════════════════════
    // 2. 函式指標宣告與初始化
    // ════════════════════
    printf("=== FP: declare & init ===\n");
    int (*fp)(int, int) = add;
    printf("fp=add: fp(10,3) = %d\n", fp(10, 3));    // 13

    // ════════════════════
    // 3. 函式指標重新賦值
    // ════════════════════
    printf("=== FP: reassign ===\n");
    fp = sub;
    printf("fp=sub: fp(10,3) = %d\n", fp(10, 3));    // 7
    fp = mul;
    printf("fp=mul: fp(10,3) = %d\n", fp(10, 3));    // 30
    fp = max2;
    printf("fp=max2: fp(10,3) = %d\n", fp(10, 3));   // 10

    // ════════════════════
    // 4. 函式指標當參數
    // ════════════════════
    printf("=== FP: as argument ===\n");
    int (*op)(int, int) = add;
    printf("apply(add,6,7) = %d\n", apply(op, 6, 7));  // 13
    op = mul;
    printf("apply(mul,6,7) = %d\n", apply(op, 6, 7));  // 42
    op = sub;
    printf("apply(sub,9,4) = %d\n", apply(op, 9, 4));  // 5

    // ════════════════════
    // 5. 函式指標 dispatch
    // ════════════════════
    printf("=== FP: dispatch ===\n");
    printf("dispatch(0,4,5) = %d\n", dispatch(0, 4, 5));  // add: 9
    printf("dispatch(1,4,5) = %d\n", dispatch(1, 4, 5));  // sub: -1
    printf("dispatch(2,4,5) = %d\n", dispatch(2, 4, 5));  // mul: 20

    // ════════════════════
    // 6. 宣告後再賦值
    // ════════════════════
    printf("=== FP: declare then assign ===\n");
    int (*g)(int, int);
    g = add;
    printf("g=add: g(100,200) = %d\n", g(100, 200));  // 300
    g = sub;
    printf("g=sub: g(100,200) = %d\n", g(100, 200));  // -100

    return 0;
}
