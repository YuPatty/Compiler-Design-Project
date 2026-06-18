/* =====================================================
   test_scope.c
   二、變數宣告、作用域
   1. 多變數同行宣告（含初始值）
   2. 全域/區域雙軌符號表 + Shadowing
   3. for 迴圈變數 scope 隔離
   4. const 變數防護
   5. 語意防禦（TypeInfo.Error 防崩潰）
   ===================================================== */

/* ── 全域變數 ── */
int g_count = 0;
float g_ratio = 1.5;
int g_x = 100;
int g_y = 200;

int main(void) {

    /* ---------------------------------------------------
       1. 多變數同行宣告（含初始值）
       --------------------------------------------------- */
    printf("--- 1. Multi-variable declaration ---\n");

    int a, b, c;
    a = 1;
    b = 2;
    c = 3;
    printf("a=%d b=%d c=%d\n", a, b, c);

    int x = 10, y = 20, z = 30;
    printf("x=%d y=%d z=%d\n", x, y, z);

    float f1 = 1.1, f2 = 2.2, f3 = 3.3;
    printf("f1=%f f2=%f f3=%f\n", f1, f2, f3);

    int p = 5, q = p + 3;
    printf("p=%d q=%d\n", p, q);

    int zero = 0, one = 1, neg = -99;
    printf("zero=%d one=%d neg=%d\n", zero, one, neg);

    /* ---------------------------------------------------
       2. 全域/區域雙軌符號表 + Shadowing
       --------------------------------------------------- */
    printf("--- 2. Global/Local + Shadowing ---\n");

    printf("g_count=%d\n", g_count);
    printf("g_ratio=%f\n", g_ratio);
    printf("g_x=%d g_y=%d\n", g_x, g_y);

    g_count = 42;
    printf("g_count after assign=%d\n", g_count);

    int g_x = 999;
    printf("local g_x=%d\n", g_x);
    printf("global g_y still=%d\n", g_y);

    {
        int g_x = 777;
        printf("inner g_x=%d\n", g_x);

        int local_only = 55;
        printf("local_only=%d\n", local_only);

        {
            int g_x = 333;
            printf("innermost g_x=%d\n", g_x);
        }
        printf("inner g_x after innermost=%d\n", g_x);
    }
    printf("outer g_x after block=%d\n", g_x);

    int sv = 1;
    printf("sv=%d\n", sv);
    {
        int sv = 2;
        printf("inner sv=%d\n", sv);
        {
            int sv = 3;
            printf("innermost sv=%d\n", sv);
        }
        printf("inner sv after=%d\n", sv);
    }
    printf("outer sv after=%d\n", sv);

    /* ---------------------------------------------------
       3. for 迴圈變數 scope 隔離
       --------------------------------------------------- */
    printf("--- 3. for-loop scope ---\n");

    int i = 100;
    printf("i before for=%d\n", i);

    int sum = 0;
    for (int i = 0; i < 5; i++) {
        sum = sum + i;
    }
    printf("sum(0..4)=%d\n", sum);
    printf("i after for=%d\n", i);

    int j = 999;
    for (int j = 10; j < 13; j++) {
        printf("j in loop=%d\n", j);
    }
    printf("j after for=%d\n", j);

    int total = 0;
    for (int k = 1; k <= 5; k++) {
        for (int m = 1; m <= 3; m++) {
            total = total + 1;
        }
    }
    printf("total nested loops=%d\n", total);

    /* ---------------------------------------------------
       4. const 變數防護
       --------------------------------------------------- */
    printf("--- 4. const ---\n");

    const int MAX = 100;
    const float PI = 3.14159;
    const int ZERO = 0;

    printf("MAX=%d\n", MAX);
    printf("PI=%f\n", PI);
    printf("ZERO=%d\n", ZERO);

    if (MAX > 50) printf("MAX>50 OK\n");
    if (PI > 3.0) printf("PI>3.0 OK\n");

    int arr[MAX];
    arr[0] = 1;
    arr[99] = 99;
    printf("arr[0]=%d arr[99]=%d\n", arr[0], arr[99]);

    /* ---------------------------------------------------
       5. 語意防禦（未宣告識別字不崩潰，繼續編譯）
       --------------------------------------------------- */
    printf("--- 5. Semantic defense ---\n");

    int valid = 42;
    printf("valid=%d\n", valid);

    int result = valid + 1;
    printf("result=%d\n", result);

    int chain = result * 2 + valid;
    printf("chain=%d\n", chain);

    printf("done\n");

    return 0;
}
