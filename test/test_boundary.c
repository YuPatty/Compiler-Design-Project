// test_boundary.c
// 測試 myCompiler 的邊界條件與語意防禦機制
// 注意：故意包含各種語意錯誤，目的是觸發編譯器的 Error 訊息！
// 本檔案「不應」成功產出可執行的二進位檔，只應產生 STDERR 錯誤訊息。

// -----------------------------------------
// 1. 函式重複定義 (Redeclare Function)
// -----------------------------------------
int duplicate_func() {
    return 1;
}

int duplicate_func() {  // 預期 STDERR: Redeclared function duplicate_func
    return 2;
}

// -----------------------------------------
// 2. 正常輔助函式
// -----------------------------------------
void print_nums(int a, int b) {
    printf("%d, %d\n", a, b);
}

int main() {
    // -----------------------------------------
    // 3. 變數未宣告即使用 (Undeclared Variable)
    // -----------------------------------------
    undeclared_var = 10; // 預期 STDERR: Undeclared identifier 'undeclared_var'

    // -----------------------------------------
    // 4. 變數重複宣告 (Redeclare Variable)
    // -----------------------------------------
    int x = 5;
    int x = 10;  // 預期 STDERR: Redeclared identifier x

    // -----------------------------------------
    // 5. 作用域隔離與 Shadowing 邊界
    // -----------------------------------------
    {
        int y = 20;
        int x = 100;  // 合法：內部遮蔽外部
    }
    y = 30;  // 預期 STDERR: Undeclared identifier 'y'

    // -----------------------------------------
    // 6. 型別錯置（Type Mismatch）     ← 新增
    // -----------------------------------------
    int* ptr = 0;
    int bad_deref = *ptr;  // 合法語法，但 ptr 為 null（執行期）
    // 以下為編譯期型別錯置：對非指標取值
    int normal_var = 100;
    int val = *normal_var; // 預期 STDERR: 'normal_var' is not a pointer

    // -----------------------------------------
    // 7. 呼叫未定義的函式
    // -----------------------------------------
    unknown_function();  // 預期 STDERR: Undeclared function 'unknown_function'

    // -----------------------------------------
    // 8. 函式參數數量不匹配
    // -----------------------------------------
    print_nums(1);       // 預期 STDERR: argument count mismatch
    print_nums(1, 2, 3); // 預期 STDERR: argument count mismatch

    // -----------------------------------------
    // 9. 非法的 break / continue
    // -----------------------------------------
    break;    // 預期 STDERR: break not within loop or switch
    continue; // 預期 STDERR: continue not within a loop

    // -----------------------------------------
    // 10. 非 struct 使用 .field
    // -----------------------------------------
    int not_struct = 5;
    not_struct.field = 10; // 預期 STDERR: 'not_struct' is not a struct

    return 0;
}
