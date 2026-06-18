// test_linked_list.c
struct Node {
    int data;
    struct Node* next;
};

// ── 功能 1：動態建立節點 ──
struct Node* create_node(int val) {
    int sz;
    sz = sizeof(struct Node);
    
    struct Node* new_node;
    // ✨ 修改 1：拿掉 (struct Node*) 強制轉型！
    // 讓你的編譯器發揮「自動指標轉型」的超能力！
    new_node = malloc(sz); 
    
    new_node->data = val;
    new_node->next = 0; 
    
    return new_node;
}

// ── 功能 2：走訪並插入節點 ──
struct Node* append_node(struct Node* head, int val) {
    struct Node* new_node;
    new_node = create_node(val);

    if (head == 0) {
        return new_node;
    }

    struct Node* curr;
    curr = head;
    
    while (curr->next != 0) {
        curr = curr->next;
    }
    
    curr->next = new_node;
    
    return head;
}

// ── 功能 3：走訪並印出 ──
void print_list(struct Node* head) {
    struct Node* curr;
    curr = head;
    printf("List: ");
    while (curr != 0) {
        printf("[%d] -> ", curr->data);
        curr = curr->next;
    }
    printf("NULL\n");
}

// ── 功能 4：釋放記憶體 ──
void free_list(struct Node* head) {
    struct Node* curr;
    curr = head;
    while (curr != 0) {
        struct Node* temp;
        temp = curr;
        curr = curr->next;
        free(temp); 
    }
}

int main(void) {
    printf("=== Linked List Test ===\n");

    struct Node* head;
    head = 0; 

    printf("Appending 10, 20, 30...\n");
    head = append_node(head, 10);
    head = append_node(head, 20);
    head = append_node(head, 30);
    print_list(head);

    printf("=== Modify 2nd Node ===\n");
    if (head != 0) {
        // ✨ 修改 2：用暫存變數拆解 head->next->data，避開雙重箭頭語法限制
        struct Node* second;
        second = head->next;
        if (second != 0) {
            second->data = 99; 
        }
    }
    print_list(head);

    printf("=== Freeing List ===\n");
    free_list(head);
    printf("Free OK!\n");

    return 0;
}