// ============================================================
// test_bounds_static_warn.c
// 專門測試靜態邊界 Warning：
//   索引為編譯期常數且越界 → 編譯時 stderr 印出 Warning
//   但程式仍能繼續編譯（Warning 不是 Error）
// ============================================================

#include <stdio.h>

int main() {
    int arr[3] = {10, 20, 30};

    // 合法
    printf("arr[0]=%d arr[2]=%d\n", arr[0], arr[2]);

    // 越界常數索引（index 5，size 3）
    // 編譯時 stderr 應印：
    //   Warning! 19: array index 5 is out of bounds for 'arr' (size 3).
    arr[5] = 99;

    printf("done\n");
    return 0;
}
