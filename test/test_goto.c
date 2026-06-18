// test_goto.c
// 測試 goto + labeled statement 的四種情境

// ─────────────────────────────────────────
// 情境 1：backward goto（模擬簡單迴圈）
// ─────────────────────────────────────────
void test_backward() {
    int i = 0;
    int sum = 0;

loop:
    if (i >= 5) goto done;
    sum = sum + i;
    i = i + 1;
    goto loop;

done:
    printf("backward: sum = %d\n", sum);   // 0+1+2+3+4 = 10
}

// ─────────────────────────────────────────
// 情境 2：forward goto（跳過一段程式碼）
// ─────────────────────────────────────────
void test_forward() {
    int x = 100;
    goto skip;

    x = 999;              // 這行應被跳過

skip:
    printf("forward: x = %d\n", x);       // 100
}

// ─────────────────────────────────────────
// 情境 3：巢狀迴圈中用 goto 跳出雙層
// ─────────────────────────────────────────
void test_nested_break() {
    int found = 0;
    int i = 0;
    while (i < 5) {
        int j = 0;
        while (j < 5) {
            if (i * 5 + j == 13) {
                found = 1;
                goto exit_loops;   // forward goto 跳出雙層 while
            }
            j = j + 1;
        }
        i = i + 1;
    }

exit_loops:
    printf("nested: found=%d i=%d\n", found, i);  // found=1 i=2
}

// ─────────────────────────────────────────
// 情境 4：多個 label，goto 不同目標
// ─────────────────────────────────────────
void test_multi_label(int n) {
    if (n == 1) goto label_a;
    if (n == 2) goto label_b;
    goto label_c;

label_a:
    printf("multi: branch A\n");
    goto end;

label_b:
    printf("multi: branch B\n");
    goto end;

label_c:
    printf("multi: branch C\n");

end:
    printf("multi: done (n=%d)\n", n);
}

int main() {
    test_backward();
    test_forward();
    test_nested_break();
    test_multi_label(1);
    test_multi_label(2);
    test_multi_label(3);
    return 0;
}
