// test_strict_80.c
// 助教的嚴格 80 分邊界測試 (Strict Boundary Test for 80-Point Features)

int main() {
    printf("--- Strict 80-Point Test Start ---\n");

    // 1. 單目運算子 (Unary) 與多重邏輯反轉
    // 測試：編譯器是否能正確處理連續的狀態翻轉與二補數運算
    int a; a = 10;
    int b; b = -a;       // 測試負號
    int c; c = ~0;       // Bitwise NOT 0，在 32-bit 下應該要是 -1
    int d; d = !42;      // Logical NOT 非零值，應該要是 0
    int e; e = !!(-99);  // Logical NOT NOT，應該要是 1
    printf("b=%d, c=%d, d=%d, e=%d\n", b, c, d, e);

    // 2. 負數的運算子優先權與取餘數
    // 測試：乘法優先於加減法，且負數參與計算
    int math_res;
    // 10 + (5 * -3) - (100 % 7) = 10 - 15 - 2 = -7
    math_res = 10 + 5 * -3 - (100 % 7); 
    printf("math_res = %d\n", math_res);

    // 3. 浮點數的極端精度與「負數截斷」
    float f_small; f_small = 0.0001f;
    float f_large; f_large = 10000.0f;
    float f_res;   f_res = f_large * f_small; // 應該精準等於 1.000000

    int neg_trunc;
    // 測試：負浮點數轉整數的截斷。C 語言標準是「向零捨入」，所以 -4.99 應該變成 -4，而不是 -5！
    neg_trunc = -4.99f; 
    printf("f_res = %f, neg_trunc = %d\n", f_res, neg_trunc);

    // 4. 複雜的短路邏輯與關係比較
    // 測試：各種運算子混用的 AST 解析是否正確
    if ( (a >= 10 && b < 0) || (c == -1 && d != 0) ) {
        printf("Logic branch: TRUE (Correct!)\n");
    } else {
        printf("Logic branch: FALSE (Wrong!)\n");
    }

    // 5. 巢狀 if-else 與 Dangling Else 陷阱
    // 測試：內層的 else 是否正確對應到內層的 if
    int flag; flag = 0;
    if (a == 10) {
        if (flag) {
            printf("Nested flow: WRONG!\n");
        } else {
            printf("Nested flow: CORRECT!\n");
        }
    } else {
        printf("Outer flow: WRONG!\n");
    }

    // 6. 特殊運算子的底數與指數為 0 測試
    // 測試：0.0^1.0 + 1.0^0.0 = 0 + 1 = 1.0
    float magic;
    magic = 0.0f ## 1.0f;
    printf("0.0 ## 1.0 = %f\n", magic);

    printf("--- Strict 80-Point Test End ---\n");
    return 0;
}