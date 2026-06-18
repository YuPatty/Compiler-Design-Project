// test_new5features.c
// 驗證 5 個新功能：
//   1. 前端 DCE if(1)/if(0)
//   2. Strength Reduction x*2^n / x/2^n
//   3. 指標算術 p+n
//   4. 函式回傳指標 int* foo()
//   5. malloc / free / memset / memcpy / memcmp

// ── 功能 4：函式回傳指標 ──
int* get_element(int arr[], int idx) {
    return arr + idx;
}

int* find_max_ptr(int arr[], int n) {
    int* maxp;
    maxp = arr;
    int i;
    i = 1;
    while (i < n) {
        if (*(arr + i) > *maxp) {
            maxp = arr + i;
        }
        i = i + 1;
    }
    return maxp;
}

int main(void) {

    // ════════════════════════════════
    // 1. 前端 DCE if(1)/if(0)
    //    驗證方式：觀察 .ll 中 if(1) 沒有 Ltrue/Lfalse，if(0) 同理
    // ════════════════════════════════
    printf("=== Frontend DCE ===\n");

    if (1) {
        printf("DCE: if(1) taken\n");       // 一定印出
    } else {
        printf("DCE: DEAD - not in IR\n");  // 完全不進 IR
    }

    if (0) {
        printf("DCE: DEAD - not in IR\n");  // 完全不進 IR
    } else {
        printf("DCE: if(0) else taken\n");  // 一定印出
    }

    // 常數折疊後觸發 DCE
    int always_pos;
    always_pos = 5;
    if (1) {
        printf("DCE: constant 1 OK\n");
    }

    // ════════════════════════════════
    // 2. Strength Reduction
    //    驗證方式：觀察 .ll 中出現 shl/ashr 而非 mul/sdiv
    // ════════════════════════════════
    printf("=== Strength Reduction ===\n");
    int n;
    n = 12;

    int r1; r1 = n * 2;    // shl i32 n, 1
    int r2; r2 = n * 4;    // shl i32 n, 2
    int r3; r3 = n * 8;    // shl i32 n, 3
    int r4; r4 = n * 16;   // shl i32 n, 4
    int r5; r5 = n / 2;    // ashr i32 n, 1
    int r6; r6 = n / 4;    // ashr i32 n, 2
    int r7; r7 = n / 8;    // ashr i32 n, 3
    printf("n=12: *2=%d *4=%d *8=%d *16=%d\n", r1, r2, r3, r4);
    // 預期: 24 48 96 192
    printf("n=12: /2=%d /4=%d /8=%d\n", r5, r6, r7);
    // 預期: 6 3 1

    // 非 2 的冪次：正常 mul/sdiv（不做 SR）
    int r8; r8 = n * 3;    // mul（正常）
    int r9; r9 = n / 5;    // sdiv（正常）
    printf("n=12: *3=%d /5=%d\n", r8, r9);
    // 預期: 36 2

    // ════════════════════════════════
    // 3. 指標算術 p + n
    // ════════════════════════════════
    printf("=== Pointer Arithmetic ===\n");
    int arr[5];
    arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40; arr[4] = 50;

    int *p;
    p = &arr[0];

    // p + 0, p + 1, p + 2
    printf("*(p+0) = %d\n", *(p + 0));   // 10
    printf("*(p+2) = %d\n", *(p + 2));   // 30
    printf("*(p+4) = %d\n", *(p + 4));   // 50

    // ════════════════════════════════
    // 4. 函式回傳指標
    // ════════════════════════════════
    printf("=== Return Pointer ===\n");

    int data[5];
    data[0] = 5; data[1] = 2; data[2] = 8; data[3] = 1; data[4] = 9;

    int* ep;
    ep = get_element(data, 2);
    printf("data[2] via ptr = %d\n", *ep);   // 8

    int* mp;
    mp = find_max_ptr(data, 5);
    printf("max in data = %d\n", *mp);        // 9

    // 透過回傳的指標修改值
    *ep = 100;
    printf("data[2] after modify = %d\n", data[2]);  // 100

    // ════════════════════════════════
    // 5. malloc / free / memset / memcpy / memcmp
    // ════════════════════════════════
    printf("=== malloc / free ===\n");
    int sz;
    sz = 5 * sizeof(int);   // 20 bytes
    int *heap;
    heap = malloc(sz);

    // 寫入值
    int i;
    i = 0;
    while (i < 5) {
        *(heap + i) = (i + 1) * 10;
        i = i + 1;
    }
    i = 0;
    while (i < 5) {
        printf("heap[%d] = %d\n", i, *(heap + i));
        i = i + 1;
    }
    // 預期: 10 20 30 40 50

    printf("=== memset ===\n");
    char buf[16];
    memset(buf, 0, 16);    // 全部清為 0
    buf[0] = 65; buf[1] = 66; buf[2] = 67; buf[3] = 0;  // "ABC"
    printf("after memset+fill: %s\n", buf);  // ABC

    printf("=== memcpy ===\n");
    char src[8];
    char dst[8];
    src[0]=72; src[1]=101; src[2]=108; src[3]=108; src[4]=111; src[5]=0; // Hello
    memcpy(dst, src, 6);
    printf("memcpy dst: %s\n", dst);  // Hello

    printf("=== memcmp ===\n");
    int cmp1;
    cmp1 = memcmp(src, dst, 5);
    printf("memcmp same: %d\n", cmp1);  // 0

    dst[0] = 90;  // 'Z'
    int cmp2;
    cmp2 = memcmp(src, dst, 5);
    printf("memcmp diff != 0: %d\n", (cmp2 != 0));  // 1

    printf("=== free ===\n");
    free(heap);
    printf("free OK\n");

    return 0;
}
