// test_optimizations.c
// 測試：常數折疊、代數化簡、CSE、後端 DCE、短路求值
// 驗證方式：觀察產生的 .ll 檔案中是否出現對應指令

int side_called;

int side_effect(void) {
    side_called = side_called + 1;
    return 0;
}

int main(void) {

    // ════════════════════════════
    // 1. 常數折疊（Constant Folding）
    // ════════════════════════════
    printf("=== Constant Folding ===\n");
    // 以下不應產生 mul/add 指令
    int secs;
    secs = 24 * 60 * 60;            // 直接 86400
    printf("24*60*60 = %d\n", secs);  // 86400

    int total;
    total = 100 + 200 + 300;         // 直接 600
    printf("100+200+300 = %d\n", total);  // 600

    float fconst;
    fconst = 2.0 * 3.14159;          // 直接計算
    printf("2.0*PI = %f\n", fconst);  // 6.283180

    int mix;
    mix = 3 * 4 + 5 * 6;            // 12 + 30 = 42
    printf("3*4+5*6 = %d\n", mix);   // 42

    // ════════════════════════════
    // 2. 代數化簡（Algebraic Simplification）
    // ════════════════════════════
    printf("=== Algebraic Simplification ===\n");
    int x;
    x = 7;
    int r1; r1 = x + 0;   // 不產生 add，直接用 x
    int r2; r2 = x * 1;   // 不產生 mul，直接用 x
    int r3; r3 = x * 0;   // 直接為 0
    int r4; r4 = x - 0;   // 不產生 sub，直接用 x
    printf("x+0=%d x*1=%d x*0=%d x-0=%d\n", r1, r2, r3, r4);  // 7 7 0 7

    // ════════════════════════════
    // 3. CSE（公共子式消除）
    // ════════════════════════════
    printf("=== CSE ===\n");
    int a;
    int b;
    a = 5; b = 3;
    // x*y 計算一次，第二次重用
    int p1; p1 = a * b + 10;  // a*b 計算
    int p2; p2 = a * b - 10;  // a*b 應重用（同 basic block 內）
    printf("a*b+10=%d a*b-10=%d\n", p1, p2);  // 25 5

    // ════════════════════════════
    // 4. 後端 DCE（Dead Code Elimination）
    // ════════════════════════════
    printf("=== Backend DCE ===\n");
    // DCE 會移除 store 後未被 load 的指令
    int dead;
    dead = 999;     // 這個 store 若後面立刻被覆蓋，應被消除
    dead = 100;     // 實際使用的值
    printf("dead = %d\n", dead);  // 100

    // ════════════════════════════
    // 5. 短路求值（Short-Circuit Evaluation）
    // ════════════════════════════
    printf("=== Short-Circuit ===\n");
    side_called = 0;

    // && 短路：左邊 false，右邊不執行
    int zero; zero = 0;
    if (zero && side_effect()) {
        printf("WRONG\n");
    } else {
        printf("&& short-circuit OK\n");
    }
    printf("side_called = %d (should be 0)\n", side_called);

    // || 短路：左邊 true，右邊不執行
    int one; one = 1;
    if (one || side_effect()) {
        printf("|| short-circuit OK\n");
    }
    printf("side_called = %d (should be 0)\n", side_called);

    // 短路不成立：右邊正常執行
    if (zero || side_effect()) { }
    printf("side_called = %d (should be 1)\n", side_called);

    return 0;
}
