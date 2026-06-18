// test_v7_features.c
#include <stdio.h>
#include <stdlib.h>

// ══════════════════════════════════════════════
// 1. Designated Initializer (具名初始化)
// ══════════════════════════════════════════════
struct Point {
    int x;
    int y;
    int z;
};

void test_designated_initializer() {
    printf("=== 1. Designated Initializer ===\n");
    
    // 【測試點】結構體具名初始化
    // 編譯器應將未說明的欄位（如 z）預設初始化為 0
    struct Point p = {.x = 10, .y = 20}; 
    printf("Point: x=%d, y=%d, z=%d (Expected: 10, 20, 0)\n", p.x, p.y, p.z);

    // 【測試點】陣列具名初始化（跳躍式索引）
    // 編譯器應將未指定索引（0, 1, 3）的元素填入 0
    int arr[5] = {[2] = 9, [4] = 42};
    printf("arr[0]=%d, arr[2]=%d, arr[4]=%d (Expected: 0, 9, 42)\n", arr[0], arr[2], arr[4]);
}

// ══════════════════════════════════════════════
// 2. Function Pointer Typedef (函式指標型別宣告端)
// ══════════════════════════════════════════════
// 【測試點】宣告端的 Parser 解析
// 語法規則需要識別 typedef 返回型別 (*新別名)(參數型別列表)
typedef int (*Cmp)(int, int);

int max_compare(int a, int b) {
    return (a > b) ? a : b;
}

void test_function_pointer() {
    printf("\n=== 2. Function Pointer Typedef ===\n");
    
    // 使用剛剛宣告的 Cmp 別名來宣告變數（呼叫端基本支援）
    Cmp my_cmp = max_compare;
    
    int result = my_cmp(15, 8);
    printf("Cmp result (max of 15, 8): %d (Expected: 15)\n", result);
}

// ══════════════════════════════════════════════
// 3. Bit-field (位元欄位結構體)
// ══════════════════════════════════════════════
// 【測試點】結構體記憶體佈局 (Layout) 計算與 GEP 生成
// 這三個欄位在標準 C 裡應該會被壓縮進同一個 32-bit (4 bytes) 的整數空間中
struct Status {
    unsigned int is_active : 1;  // 佔 1 bit
    unsigned int role      : 3;  // 佔 3 bits
    unsigned int flags     : 4;  // 佔 4 bits
};

void test_bit_field() {
    printf("\n=== 3. Bit-field ===\n");
    
    struct Status s;
    
    // 【測試點】寫入時的 LLVM IR 生成
    // 不能直接 store，必須用 load -> bitwise AND (清空舊位元) -> bitwise OR (寫入新位元) -> store
    s.is_active = 1;
    s.role = 5;      // 5 二進位是 101
    s.flags = 12;    // 12 二進位是 1100

    // 【測試點】讀取時的 LLVM IR 生成
    // 需要配合 GEP 取出該 byte 區塊後，進行邏輯右移 (lshr) 與遮罩 (and) 運算
    printf("Status: active=%u, role=%u, flags=%u (Expected: 1, 5, 12)\n", s.is_active, s.role, s.flags);
    
    // 驗證編譯器計算的 sizeof 是否正確（應該是 4 bytes，而不是 3 * 4 = 12 bytes）
    printf("Size of Status struct: %d bytes (Expected: 4)\n", (int)sizeof(struct Status));
}

// ══════════════════════════════════════════════
// 4. 3D Array (三維陣列，延伸自 arrayDim2)
// ══════════════════════════════════════════════
// 【測試點】多維陣列傳參與延伸的 GEP 索引計算
// 傳參時第一維可省略，寫成 grid[][3][4]
void print_and_sum_3d(int grid[2][3][4]) {
    int sum = 0;
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 3; j++) {
            for (int k = 0; k < 4; k++) {
                sum += grid[i][j][k];
            }
        }
    }
    printf("3D Array total sum = %d (Expected: 300)\n", sum);
}

void test_3d_array() {
    printf("\n=== 4. 3D Array ===\n");
    
    // 宣告 2 * 3 * 4 = 24 個元素的 3D 陣列
    int grid[2][3][4];
    int count = 1;
    
    // 初始化 3D 陣列
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 3; j++) {
            for (int k = 0; k < 4; k++) {
                grid[i][j][k] = count;
                count++;
            }
        }
    }
    
    // 【測試點】單一元素讀寫時的 GEP 指令生成
    // LLVM IR 的 GEP 需要給 4 個參數：base, index_i, index_j, index_k
    printf("grid[0][1][2] = %d (Expected: 7)\n", grid[0][1][2]);
    printf("grid[1][2][3] = %d (Expected: 24)\n", grid[1][2][3]);
    
    // 傳遞 3D 陣列給函式
    print_and_sum_3d(grid);
}

// ══════════════════════════════════════════════
// Main Entry
// ══════════════════════════════════════════════
int main() {
    test_designated_initializer();
    test_function_pointer();
    test_bit_field();
    test_3d_array();
    
    printf("\n=== 全部 v7 擴充功能驗證完畢 ===\n");
    return 0;
}