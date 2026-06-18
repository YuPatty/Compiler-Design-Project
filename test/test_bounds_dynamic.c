// ============================================================
// test_bounds_dynamic.c
// 專門測試動態邊界檢查：
//   執行期索引越界 → 印出訊息 + abort
// 這個測試預期會以非零狀態碼結束（abort）
// ============================================================

#include <stdio.h>

int main() {
    int arr[3] = {10, 20, 30};
    int idx;

    // 合法存取
    idx = 1;
    printf("arr[%d] = %d\n", idx, arr[idx]);  // arr[1] = 20

    // 越界存取（idx=5 >= size=3）→ 觸發 abort
    idx = 5;
    printf("About to access arr[%d] (out of bounds)...\n", idx);
    int val = arr[idx];   // 這行會 abort
    printf("Should not reach here: %d\n", val);
    return 0;
}
