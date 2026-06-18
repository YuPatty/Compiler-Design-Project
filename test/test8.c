// test8.c
// 測試：基本功能的邊界條件 (Boundary Cases)

int main() {
    printf("--- Boundary Test Start ---\n");

    // 1. 型別轉換邊界 (極限截斷與浮點數提升)
    // 測試：5.999 應該無條件捨去變 5，而不是四捨五入變 6
    int trunc_val;
    trunc_val = 5.999f; 
    
    float prom_val;
    prom_val = trunc_val + 0.125f; // int + float 隱式提升，應為 5.125
    printf("Truncated: %d, Promoted: %f\n", trunc_val, prom_val);

    // 2. 數學運算邊界 (包含 0 與 1 的特殊行為)
    // 測試：0 被除、對 1 取餘數
    int zero_div;
    zero_div = 0 / 42;
    
    int mod_one;
    mod_one = 100 % 1; // 任何數對 1 取餘數都應該是 0
    printf("0 / 42 = %d, 100 mod 1 = %d\n", zero_div, mod_one);

    // 3. 特殊運算子邊界 (底數為 1)
    // 測試：1.0^5.0 + 5.0^1.0 = 1.0 + 5.0 = 6.0
    float magic_base;
    magic_base = 1.0f ## 5.0f; 
    printf("1.0 ## 5.0 = %f\n", magic_base);

    // 4. 迴圈邊界：0 次迭代
    // 測試：條件一開始就不成立時，是否會錯誤地執行一次 (特別是 for 和 while 的跳轉邏輯)
    int zero_loop_cnt;
    zero_loop_cnt = 0;
    
    while (zero_loop_cnt > 10) {
        zero_loop_cnt++; // 這裡絕對不該被執行
    }
    
    int i;
    for (i = 5; i < 5; i++) {
        zero_loop_cnt++; // 這裡也絕對不該被執行
    }
    printf("Zero loop count = %d (should be 0)\n", zero_loop_cnt);

    // 5. 陣列極值與 Switch 負數跳轉
    // 測試：陣列 index 0 與 最大 index (2) 的存取
    int arr[3];
    arr[0] = 77;
    arr[1] = 88;
    arr[2] = 99;
    
    int head;
    head = arr[0];
    int tail;
    tail = arr[2];
    
    // 測試：switch 是否能正確處理負數條件 (77 - 99 = -22)
    switch (head - tail) { 
        case -22:
            printf("Array head-tail math match!\n");
            break;
        case 0:
            printf("Array math error!\n");
            break;
        default:
            printf("Switch default fallback!\n");
            break;
    }

    printf("--- Boundary Test End ---\n");
    return 0;
}