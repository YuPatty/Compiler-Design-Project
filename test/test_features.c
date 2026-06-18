// test_features.c
// 綜合測試：陣列退化、NULL 指標防護、UTF-8 中文支援、精準型別追蹤 (exactTypeMap)

struct Node {
    int id;
    struct Node* next;
};

// 📍 測試一：陣列退化 (Array Decay)
// 這裡預期接收 int*，但等一下我們會傳入 int[3] 陣列
void print_array(int* arr, int size) {
    int i = 0;
    // 📍 測試三：UTF-8 與非 ASCII 字元支援
    printf("陣列內容 (測試 UTF-8): ");
    while (i < size) {
        printf("%d ", arr[i]);
        i += 1;
    }
    printf("\n");
}

int main() {
    // 📍 測試三：中文字元長度與十六進位跳脫序列轉換
    printf("=== 開始綜合功能測試 ===\n");

    // -----------------------------------------
    // 測試一：陣列退化 (Array Decay)
    // -----------------------------------------
    int nums[3];
    nums[0] = 10;
    nums[1] = 20;
    nums[2] = 30;
    
    // nums 是 [3 x i32]*，傳入 print_array 會自動無縫轉為 i32*
    print_array(nums, 3);

    // -----------------------------------------
    // 測試二：NULL 指標防護網
    // -----------------------------------------
    // 將常數 0 賦值給指標，編譯期應精準攔截並轉為 LLVM 的 null
    struct Node* head = 0;
    int* empty_ptr = 0;

    if (head == 0) {
        printf("head 成功被初始化為 NULL (0)\n");
    }

    // -----------------------------------------
    // 測試四：全域型別追蹤小本本 (exactTypeMap)
    // -----------------------------------------
    // 1. malloc 預設回傳 i8*，強制轉型為 struct Node*
    // 2. exactTypeMap 必須記住 node1 是 %struct.Node*，而不是退化成 i8*
    struct Node* node1 = (struct Node*)malloc(16);
    
    node1->id = 99;
    node1->next = 0; // 再次觸發 NULL 指標防護網

    // 指標互相賦值：依賴 exactTypeMap 確認 head 和 node1 型別一致
    head = node1;

    // 確保 pointer math 和 getelementptr 能正確算出 id 的位址
    printf("Node ID (測試 exactTypeMap): %d\n", head->id);

    printf("=== 測試順利完成 ===\n");
    return 0;
}