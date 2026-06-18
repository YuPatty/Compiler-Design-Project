// test_new4.c
// 測試四個新功能：
//   1. break/continue 錯誤檢查（不在 loop 裡用）
//   2. void 函式 return; 正確產生 ret void
//   3. scanf 支援 %s 讀字串
//   4. Dead Code Elimination（if(1)/if(0) 消除死碼）

// ── 功能 2：void 函式 + return; ──
void say_hello(void) {
    printf("Hello from void function!\n");
    return;
}

void print_sign(int x) {
    if (x > 0) {
        printf("positive\n");
        return;
    }
    if (x < 0) {
        printf("negative\n");
        return;
    }
    printf("zero\n");
}

int main(void) {

    // ── 功能 2：呼叫 void 函式 ──
    say_hello();
    print_sign(5);
    print_sign(-3);
    print_sign(0);

    // ── 功能 3：scanf 讀 %s ──
    char name[32];
    printf("Enter your name: ");
    scanf("%s", name);
    printf("Hello, %s!\n", name);

    // ── 同時讀 %s 和 %d ──
    char city[20];
    int age;
    printf("Enter city: ");
    scanf("%s", city);
    printf("Enter age: ");
    scanf("%d", &age);
    printf("%s is %d years old.\n", city, age);

    // ── 功能 4：Dead Code Elimination ──
    // if(1)：else branch 完全不出現在 IR 裡
    if (1) {
        printf("DCE: if(1) branch taken\n");
    } else {
        printf("DCE: DEAD CODE - should not appear in IR\n");
    }

    // if(0)：true branch 完全不出現在 IR 裡
    if (0) {
        printf("DCE: DEAD CODE - should not appear in IR\n");
    } else {
        printf("DCE: if(0) else branch taken\n");
    }

    // 常數折疊產生的常數條件也觸發 DCE
    int always_true;
    always_true = 10 > 0;   // 常數折疊 → 1（待實作）
    // 直接用常數
    if (1) {
        printf("DCE: constant condition works\n");
    }

    // ── 功能 1：break/continue 在迴圈內（正確用法）──
    int i;
    i = 0;
    while (i < 10) {
        if (i == 3) {
            i = i + 1;
            continue;
        }
        if (i == 6) {
            break;
        }
        printf("loop i=%d\n", i);
        i = i + 1;
    }
    // 預期輸出：0 1 2 4 5（跳過 3，到 6 停止）

    return 0;
}
