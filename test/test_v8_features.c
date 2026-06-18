// ============================================================
// test_v8_features.c
// 測試七個新功能：
//   1. \xNN / \ooo 字元與字串逃脫序列
//   2. _Alignof
//   3. typeof
//   4. 多回傳路徑警告（編譯期 stderr，執行不受影響）
//   5. 陣列邊界靜態檢查（編譯期 stderr Warning）
//   6. 陣列邊界動態檢查（執行期 abort）
//   7. 複合字面值（Compound Literal）
// ============================================================

#include <stdio.h>

// ─────────────────────────────────────────
// 功能 4：非 void 函式沒有 return
// 編譯時應印出 Warning，執行時回傳 0
// ─────────────────────────────────────────
int missing_return(int x) {
    if (x > 0) {
        return x * 2;
    }
    // 沒有 else return → 觸發 Warning
}

// ─────────────────────────────────────────
// 功能 3：typeof 用於泛型 SWAP 巨集
// ─────────────────────────────────────────
#define SWAP(a, b) do { typeof(a) _tmp = (a); (a) = (b); (b) = _tmp; } while(0)

// ─────────────────────────────────────────
// 功能 7：複合字面值 helper
// ─────────────────────────────────────────
int sum_array(int *arr, int n) {
    int s = 0;
    int i;
    for (i = 0; i < n; i++) s += arr[i];
    return s;
}

int main() {

    // ── 1. \xNN 十六進位逃脫序列 ──────────────────────
    char hex_A = '\x41';          // 0x41 = 65 = 'A'
    char hex_nl = '\x0A';         // 0x0A = newline
    printf("Test 1a \\xNN char: %c\n", hex_A);          // A
    printf("Test 1b \\xNN in string: %s", "Hi\x0A");    // Hi + newline

    // \ooo 八進位逃脫序列
    char oct_A = '\101';          // 八進位 101 = 65 = 'A'
    char oct_tab = '\011';        // 八進位 011 = 9 = tab
    printf("Test 1c \\ooo char: %c\n", oct_A);          // A
    printf("Test 1d \\ooo tab:[%c]end\n", oct_tab);     // [	]

    // 字串中的 \xNN
    printf("Test 1e string \\x41\\x42\\x43: %s\n", "\x41\x42\x43"); // ABC

    // ── 2. _Alignof ────────────────────────────────────
    int al_char   = _Alignof(char);       // 1
    int al_short  = _Alignof(short);      // 2
    int al_int    = _Alignof(int);        // 4
    int al_double = _Alignof(double);     // 8
    printf("Test 2 _Alignof: char=%d short=%d int=%d double=%d\n",
           al_char, al_short, al_int, al_double);  // 1 2 4 8

    // ── 3. typeof ──────────────────────────────────────
    int   ti = 10, tj = 20;
    float tf = 1.5, tg = 9.5;
    SWAP(ti, tj);
    SWAP(tf, tg);
    printf("Test 3a typeof int  SWAP: ti=%d tj=%d\n", ti, tj);    // 20 10
    printf("Test 3b typeof float SWAP: tf=%.1f tg=%.1f\n", tf, tg); // 9.5 1.5

    // typeof 直接宣告變數
    int base = 42;
    typeof(base) copy = base;
    copy += 8;
    printf("Test 3c typeof var: base=%d copy=%d\n", base, copy);  // 42 50

    // ── 4. 多回傳路徑警告（執行正常，回傳 0）─────────
    int r1 = missing_return(5);    // 有 return：10
    int r2 = missing_return(-1);   // 沒有 return：補的 ret i32 0 → 0
    printf("Test 4 missing return: r1=%d r2=%d\n", r1, r2); // 10 0

    // ── 5. 靜態邊界檢查（編譯期 Warning，執行繼續）──
    int arr5[3] = {10, 20, 30};
    // 以下存取索引 2 是合法的，不會觸發 warning
    printf("Test 5a static bounds OK: arr[2]=%d\n", arr5[2]);  // 30
    // 索引 0 也合法
    arr5[0] = 99;
    printf("Test 5b static bounds write OK: arr[0]=%d\n", arr5[0]); // 99

    // ── 6. 動態邊界檢查 ────────────────────────────────
    // 用合法索引（不觸發 abort）
    int arr6[4] = {1, 2, 3, 4};
    int idx = 3;
    printf("Test 6 dynamic bounds OK: arr[%d]=%d\n", idx, arr6[idx]); // 3

    // ── 7. 複合字面值（Compound Literal）──────────────
    // 陣列複合字面值傳給函式
    int total = sum_array((int[]){5, 10, 15, 20}, 4);
    printf("Test 7a compound literal array sum: %d\n", total);  // 50

    // 直接存取複合字面值元素
    int *p = (int[]){100, 200, 300};
    printf("Test 7b compound literal ptr: %d %d %d\n", p[0], p[1], p[2]); // 100 200 300

    // 純量複合字面值
    int sv = (int){77};
    printf("Test 7c compound literal scalar: %d\n", sv);  // 77

    printf("All tests passed.\n");
    return 0;
}
