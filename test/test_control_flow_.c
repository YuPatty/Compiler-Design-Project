// ======================================================
// test_control_flow.c
// 三、控制流：while / do-while / for / 巢狀混用 / switch-case / break / continue
// ======================================================

int main() {

    // ════════════════════════════════
    // 1. while
    // ════════════════════════════════
    printf("=== while ===\n");
    int i; i = 1;
    while (i <= 5) {
        printf("%d\n", i);
        i++;
    }
    // while 條件一開始就是 false（0 次）
    i = 10;
    while (i < 5) {
        printf("never\n");
        i++;
    }
    printf("ok\n");

    // ════════════════════════════════
    // 2. do-while
    // ════════════════════════════════
    printf("=== do-while ===\n");
    int d; d = 1;
    do {
        printf("%d\n", d);
        d++;
    } while (d <= 3);
    // 條件一開始就 false，但至少執行一次
    int e; e = 99;
    do {
        printf("%d\n", e);
        e++;
    } while (e < 99);

    // ════════════════════════════════
    // 3. for
    // ════════════════════════════════
    printf("=== for ===\n");
    int s; s = 0;
    int j;
    for (j = 1; j <= 10; j++) {
        s += j;
    }
    printf("%d\n", s);     // 55
    // 逆向
    for (j = 3; j >= 1; j--) {
        printf("%d\n", j); // 3 2 1
    }
    // for 0 次
    for (j = 5; j < 5; j++) {
        printf("never\n");
    }
    printf("ok\n");

    // ════════════════════════════════
    // 4. 巢狀迴圈混用（for + while + do-while）
    // ════════════════════════════════
    printf("=== nested mixed ===\n");
    // for 外層 + while 內層
    for (i = 1; i <= 3; i++) {
        j = 1;
        while (j <= 3) {
            printf("%d\n", i * j);
            j++;
        }
    }
    // while 外層 + for 內層
    int r; r = 0;
    i = 1;
    while (i <= 3) {
        for (j = 1; j <= i; j++) {
            r += j;
        }
        i++;
    }
    printf("%d\n", r);   // 1+(1+2)+(1+2+3)=10
    // 三層巢狀：for + while + do-while
    int cnt; cnt = 0;
    for (i = 0; i < 2; i++) {
        j = 0;
        while (j < 2) {
            int k; k = 0;
            do {
                cnt++;
                k++;
            } while (k < 2);
            j++;
        }
    }
    printf("%d\n", cnt);   // 2*2*2 = 8

    // ════════════════════════════════
    // 5. switch-case（原生 LLVM switch）
    // ════════════════════════════════
    printf("=== switch-case ===\n");
    // 一般 case
    int c; c = 2;
    switch (c) {
        case 1: printf("one\n");   break;
        case 2: printf("two\n");   break;
        case 3: printf("three\n"); break;
        default: printf("other\n"); break;
    }
    // default
    c = 9;
    switch (c) {
        case 1: printf("one\n"); break;
        case 2: printf("two\n"); break;
        default: printf("nine\n"); break;
    }
    // switch 在迴圈內
    for (i = 0; i < 4; i++) {
        switch (i) {
            case 0: printf("zero\n");  break;
            case 1: printf("one\n");   break;
            case 2: printf("two\n");   break;
            default: printf("many\n"); break;
        }
    }
    // switch 以變數算出的值
    int base; base = 10;
    switch (base / 5) {
        case 1: printf("div1\n"); break;
        case 2: printf("div2\n"); break;
        default: printf("divx\n"); break;
    }

    // ════════════════════════════════
    // 6. break（Loop Label Stack）
    // ════════════════════════════════
    printf("=== break ===\n");
    // while break
    i = 0;
    while (i < 10) {
        if (i == 5) { break; }
        printf("%d\n", i);   // 0 1 2 3 4
        i++;
    }
    printf("after %d\n", i);  // after 5
    // for break
    for (j = 0; j < 10; j++) {
        if (j == 3) { break; }
        printf("%d\n", j);   // 0 1 2
    }
    printf("after %d\n", j);  // after 3
    // 巢狀 break 只跳出內層
    for (i = 0; i < 3; i++) {
        for (j = 0; j < 3; j++) {
            if (j == 1) { break; }
            printf("%d%d\n", i, j);   // 00 10 20
        }
    }
    // do-while break
    d = 0;
    do {
        if (d == 2) { break; }
        printf("%d\n", d);   // 0 1
        d++;
    } while (d < 5);
    printf("after %d\n", d);  // after 2

    // ════════════════════════════════
    // 7. continue（Loop Label Stack）
    // ════════════════════════════════
    printf("=== continue ===\n");
    // while continue：跳過偶數
    i = 0;
    while (i < 8) {
        i++;
        if (i % 2 == 0) { continue; }
        printf("%d\n", i);   // 1 3 5 7
    }
    // for continue：跳過 3 的倍數
    for (j = 1; j <= 9; j++) {
        if (j % 3 == 0) { continue; }
        printf("%d\n", j);   // 1 2 4 5 7 8
    }
    // 巢狀 continue 只影響內層
    for (i = 0; i < 3; i++) {
        for (j = 0; j < 4; j++) {
            if (j == 2) { continue; }
            printf("%d%d\n", i, j);  // 00 01 03 / 10 11 13 / 20 21 23
        }
    }

    return 0;
}
