// test_pointer_struct.c
// 測試：struct、malloc、-> 箭頭運算子、free、多重指標 **

struct Node {
    int data;
    struct Node* next;
};

int main() {
    printf("=== Testing malloc and arrow operator (->) ===\n");

    // 1. malloc + (struct Node*) 強制轉型
    struct Node* head   = (struct Node*)malloc(16);
    struct Node* second = (struct Node*)malloc(16);

    // 2. -> 箭頭運算子寫入
    head->data = 100;
    head->next = second;
    second->data = 200;
    second->next = 0;

    // 3. -> 箭頭運算子讀取
    int a = head->data;
    printf("Head node data: %d\n", a);
    struct Node* temp = head->next;
    int b = temp->data;
    printf("Second node data: %d\n", b);

    // 4. 多重指標 **                     ← 新增
    printf("=== Multi-level pointer ** ===\n");
    struct Node** pp = &head;
    printf("pp->data via **: %d\n", (*pp)->data);
    int x = 42;
    int* px = &x;
    int** ppx = &px;
    printf("**ppx = %d\n", **ppx);
    **ppx = 99;
    printf("after **ppx=99, x = %d\n", x);

    // 5. free
    free(head);
    free(second);
    printf("=== Memory freed successfully! ===\n");

    return 0;
}
