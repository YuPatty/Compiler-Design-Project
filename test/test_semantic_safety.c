// ============================================================
// test_semantic_safety.c
// 測試功能：
// 1. 跳退字元全解析 (Escape Sequences)
// 2. (void) 顯式強迫轉型放行
// 3. L-value 與 R-value 審查 (非法賦值攔截)
// 4. 語意分析防護網 (未宣告、重複宣告攔截)
// ============================================================

#include <stdio.h>

int main() {
    // ── 1. 跳退字元 (Escape Sequences) ──
    // 測試 Lexer 是否能完美放行並解析所有合法的 C 跳脫字元
    char nl = '\n';
    char tab = '\t';
    char slash = '\\';
    char sq = '\'';
    char dq = '\"';
    char hex = '\x41'; // 16進位 'A'
    char oct = '\102'; //  8進位 'B'
    
    printf("=== 1. Escape Sequences ===\n");
    printf("Quotes & Slash: [%c] [%c] [%c]\n", sq, dq, slash);
    printf("Hex & Oct: [%c] [%c]\n", hex, oct);
    printf("String test: \"Hello\\tWorld\\n\"\n");

    // ── 2. (void) 顯式轉型放行 ──
    // 測試剛修好的 (void) 轉型，不應觸發 "Cannot cast to void"
    int var = 42;
    (void)0;     // 忽略常數
    (void)var;   // 忽略變數 (常用於消除 unused variable 警告)
    printf("=== 2. (void) Cast Passed ===\n");

    // ========================================================
    // 🛑 警告：以下區塊為「語意防呆」測試
    // 你的編譯器在處理到以下程式碼時，應該要印出 Error! 訊息，
    // 並且觸發 Error Recovery (也就是不崩潰，或者優雅地中斷編譯)。
    // ========================================================
/*
    // ── 3. L-value 與 R-value 審查 ──
    // 💣 非法：字面值 (R-value) 不能放在等號左邊
    100 = var; 

    // 💣 非法：運算結果 (R-value) 不能放在等號左邊
    (var + 10) = 50;

    // ── 4. 語意分析防護網 ──
    // 💣 非法：使用未宣告的變數
    fake_var = 99;

    // 💣 非法：重複宣告同名變數
    int var = 10;

    return 0;
    */
}