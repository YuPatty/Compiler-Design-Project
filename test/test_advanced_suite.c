int main() {
    // ── 測試 1：16 進位 (0x) 與 2 進位 (0b) 字面值 ──
    int hex_val = 0x1A;      // 應該被解析為十進位的 26
    int bin_val = 0b1010;    // 應該被解析為十進位的 10
    int sum = hex_val + bin_val; // sum 應該是 36
    
    // ── 測試 2：科學記號與精度後綴解析 ──
    double sci_val = 1.5e3;  // 應該被解析為 1500.0 (double)
    float float_val = 3.14f; // 應該被解析為 float 型別，截斷精度
    
    // ── 測試 3：巨集/自訂字串拼接 (##) ──
    // 根據你之前的實作，'##' 被定義為針對 float 的自訂運算子
    float hash_res = 2.0f ## 3.0f; // 應該呼叫 @my_hashhash
    
    // ── 測試 4：for 迴圈變數 scope 隔離 ──
    int i = 999; // 外層的 i
    
    for (int i = 0; i < 2; i++) {
        // 這裡的 i 是迴圈專屬的作用域，不會影響外面的 i
        int temp = i;
        
        // ── 測試 5：位元複合賦值 ──
        temp <<= 1;  // 等同於 temp = temp << 1
        temp |= 0x01; // 等同於 temp = temp | 1
    }
    
    // 迴圈結束後，外層的 i 依然必須是 999
    printf("Outer i = %d\n", i); 

    return 0;
}