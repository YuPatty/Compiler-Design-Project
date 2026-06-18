// ========================================================
// 函式 Prototype vs Definition 衝突檢查 綜合測試
// ========================================================

// --- 正常：互遞迴 prototype ---
int isEven(int n);
int isOdd(int n);

// --- 錯誤①：重複 prototype 回傳型別不一致 ---
int  dupProto(int x);
float dupProto(int x);   // Error: Prototype return type mismatch for dupProto.

// --- 錯誤②：definition 回傳型別與 prototype 不一致 ---
float retMismatch(int x);
int retMismatch(int x) { return x + 1; }  // Error: Definition return type does not match prototype for retMismatch.

// --- 錯誤③：prototype vs definition 參數數量不一致 ---
int paramCount(int a, int b);
int paramCount(int a) { return a; }  // Error: Parameter count mismatch for 'paramCount'

// --- 錯誤④：prototype vs definition 逐位參數型別不一致 ---
int paramType(float x, int y);
int paramType(int x, int y) { return x + y; }  // Error: Parameter 1 type mismatch for 'paramType'

// --- 正常：struct 回傳 + 指標回傳 prototype 一致 ---
typedef struct { int x; int y; } Point;
Point makePoint(int x, int y);
int*  getFirst(int* arr, int n);

// --- 錯誤⑤：重複 definition ---
int redefFunc(int x) { return x + 1; }
int redefFunc(int x) { return x + 2; }  // Error: Function redefFunc already defined.

// ========== 正常函式實作 ==========

int isEven(int n) { if (n == 0) return 1; return isOdd(n - 1); }
int isOdd(int n)  { if (n == 0) return 0; return isEven(n - 1); }

int dupProto(int x) { return x; }

Point makePoint(int x, int y) {
    Point p; p.x = x; p.y = y; return p;
}

int* getFirst(int* arr, int n) { return arr; }

// ========== main ==========
int main() {
    // 正常輸出
    printf("isEven(4)=%d\n", isEven(4));   // 預期：isEven(4)=1
    printf("isOdd(3)=%d\n",  isOdd(3));    // 預期：isOdd(3)=1

    Point p = makePoint(3, 7);
    printf("Point=(%d,%d)\n", p.x, p.y);   // 預期：Point=(3,7)

    int arr[3]; arr[0]=55; arr[1]=66; arr[2]=77;
    int* ptr = getFirst(arr, 3);
    printf("first=%d\n", *ptr);             // 預期：first=55

    printf("redefFunc=%d\n", redefFunc(10)); // 預期：redefFunc=11 (第一個)

    // --- 錯誤⑥：call-site 引數過多 ---
    int r1 = isEven(4, 99);   // Error: Function 'isEven' expects 1 argument(s), but 2 provided.

    // --- 錯誤⑦：call-site 引數不足 ---
    int r2 = makePoint(1);    // Error: Function 'makePoint' expects 2 argument(s), but 1 provided.

    // --- 正常：printf 是 variadic，不應誤報 ---
    printf("%d %d %d\n", 1, 2, 3);          // 預期：1 2 3

    return 0;
}
