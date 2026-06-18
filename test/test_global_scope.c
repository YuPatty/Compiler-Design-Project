// test_global_scope.c
// 測試：全域變數、區域遮蔽（Shadowing）、雙軌符號表

int g_count = 0;
float g_pi = 3.14159;
int g_arr[5];

void increment(void) {
    g_count = g_count + 1;
}

void reset(void) {
    g_count = 0;
}

int get_count(void) {
    return g_count;
}

// 測試 shadowing：區域 g_count 遮蔽全域 g_count
void shadow_test(void) {
    int g_count;       // 區域變數遮蔽全域
    g_count = 999;
    printf("local  g_count = %d\n", g_count);  // 999
}

int main(void) {
    printf("=== 全域變數讀寫 ===\n");
    printf("initial g_count = %d\n", g_count);  // 0
    increment();
    increment();
    increment();
    printf("after 3 increments = %d\n", get_count());  // 3
    reset();
    printf("after reset = %d\n", g_count);  // 0

    printf("=== 全域 float ===\n");
    printf("g_pi = %f\n", g_pi);          // 3.141590
    g_pi = 2.71828;
    printf("g_pi modified = %f\n", g_pi); // 2.718280

    printf("=== 全域陣列 ===\n");
    int i;
    i = 0;
    while (i < 5) {
        g_arr[i] = i * 10;
        i = i + 1;
    }
    i = 0;
    while (i < 5) {
        printf("g_arr[%d] = %d\n", i, g_arr[i]);  // 0 10 20 30 40
        i = i + 1;
    }

    printf("=== 區域遮蔽（Shadowing）===\n");
    g_count = 42;
    printf("global g_count = %d\n", g_count);  // 42
    shadow_test();                              // 印 999
    printf("global g_count after shadow = %d\n", g_count);  // 仍是 42

    printf("=== for 迴圈 scope 隔離 ===\n");
    int j;
    j = 777;
    for (int j = 0; j < 3; j++) {
        printf("for-local j = %d\n", j);  // 0 1 2
    }
    printf("outer j = %d\n", j);  // 777（未受 for 內 j 影響）

    return 0;
}
