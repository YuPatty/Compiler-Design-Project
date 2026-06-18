// test_char_recursion.c
// 綜合測試：
// 1. printf("%c", ch) — char 純量 sext
// 2. char 運算的 sext 提升
// 3. char 指派的 trunc/sext 轉型
// 4. char[] 字串字面值初始化
// 5. 遞迴函式 (Recursive Function)

// 5. 遞迴函式測試：計算階乘 (Factorial)
// 測試編譯器是否能正確處理函式的 Stack Frame 與遞迴呼叫
int factorial(int n) {
    if (n <= 1) {
        return 1;
    } else {
        return n * factorial(n - 1);
    }
}

int main(void) {
    printf("--- Char & Recursion Test Start ---\n");

    // 4. char[] 字串字面值初始化
    // 測試：將字串拆解為 bytes 並存入 char 陣列
    char str[20] = "Compiler Magic!";
    printf("Feature 4 (String Init)     : %s\n", str);

    // 3. char 指派的 trunc/sext 轉型
    int origin_ascii = 72;      // ASCII 72 是 'H'
    char ch = origin_ascii;     // 隱式轉型：int -> char (觸發 trunc i32 to i8)
    int back_to_int = ch;       // 隱式轉型：char -> int (觸發 sext i8 to i32)
    
    printf("Feature 3 (Assign Cast)     : origin=%d, back_to_int=%d\n", origin_ascii, back_to_int);

    // 2. char 運算的 sext 提升
    // 測試：ch 參與加法前，會觸發 charPromote 提升為 i32，算完再存回 i8 的 next_ch
    char next_ch = ch + 1;      // 'H' (72) + 1 = 'I' (73)

    // 1. printf("%c", ch) — char 純量 sext
    // 測試：傳遞 char 給 varargs (printf) 時，自動提升為 i32 以符合 C 語言標準
    printf("Feature 1 & 2 (Math & %%c)  : Original='%c', Next='%c'\n", ch, next_ch);

    // 5. 驗證遞迴函式的執行結果
    int num = 5;
    int fact_result = factorial(num);
    printf("Feature 5 (Recursion)       : factorial(%d) = %d\n", num, fact_result);

    printf("--- Char & Recursion Test End ---\n");
    return 0;
}