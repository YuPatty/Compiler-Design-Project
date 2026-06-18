// test_new_features.c
// 測試三個新功能：
//   1. 三元運算子 (Ternary Operator)
//   2. 陣列初始化清單 (Array Initialization List)
//   3. 常數折疊 (Constant Folding)

int main(void) {

    // ========================================
    // 功能一：三元運算子 ? :
    // ========================================

    // 基本 int 三元運算子
    int a;
    int b;
    int max;
    a = 10;
    b = 20;
    max = (a > b) ? a : b;
    printf("Test1 max(10,20)     = %d\n", max);   // 預期: 20

    // 條件為假的情況
    int min;
    min = (a < b) ? b : a;
    printf("Test2 wrong_min      = %d\n", min);   // 預期: 20 (條件 a<b 為真，回傳 b)

    // 正確 min
    int min2;
    min2 = (a < b) ? a : b;
    printf("Test3 min(10,20)     = %d\n", min2);  // 預期: 10

    // 三元結果做運算
    int result;
    result = (a > b) ? a + 1 : b + 1;
    printf("Test4 ternary+arith  = %d\n", result); // 預期: 21

    // 巢狀三元運算子
    int c;
    c = 15;
    int mid;
    mid = (a > b) ? a : ((b > c) ? b : c);
    printf("Test5 nested ternary = %d\n", mid);   // 預期: 20

    // float 三元運算子
    float fa;
    float fb;
    float fmax;
    fa = 3.14;
    fb = 2.71;
    fmax = (fa > fb) ? fa : fb;
    printf("Test6 fmax(3.14,2.71)= %f\n", fmax);  // 預期: 3.140000

    // int/float 混合型別三元運算子（結果應為 float）
    float fmix;
    fmix = (a > 5) ? fa : 0;
    printf("Test7 int->float mix = %f\n", fmix);  // 預期: 3.140000

    // ========================================
    // 功能二：陣列初始化清單
    // ========================================

    // int 陣列初始化
    int arr[5] = {10, 20, 30, 40, 50};
    printf("Test8  arr[0]=%d\n", arr[0]);  // 預期: 10
    printf("Test9  arr[2]=%d\n", arr[2]);  // 預期: 30
    printf("Test10 arr[4]=%d\n", arr[4]);  // 預期: 50

    // 修改初始化後的陣列元素
    arr[1] = 99;
    printf("Test11 arr[1]=99     = %d\n", arr[1]);  // 預期: 99

    // float 陣列初始化
    float farr[3] = {1.1, 2.2, 3.3};
    printf("Test12 farr[0]       = %f\n", farr[0]);  // 預期: 1.100000
    printf("Test13 farr[1]       = %f\n", farr[1]);  // 預期: 2.200000
    printf("Test14 farr[2]       = %f\n", farr[2]);  // 預期: 3.300000

    // 陣列初始化後用迴圈走訪
    int sum;
    int i;
    sum = 0;
    i = 0;
    while (i < 5) {
        sum = sum + arr[i];
        i = i + 1;
    }
    // arr = {10, 99, 30, 40, 50} → sum = 229
    printf("Test15 arr sum       = %d\n", sum);  // 預期: 229

    // ========================================
    // 功能三：常數折疊 (Constant Folding)
    // ========================================

    // 應該只產生一個 store，不產生 mul 指令
    int secs;
    secs = 24 * 60 * 60;
    printf("Test16 24*60*60      = %d\n", secs);  // 預期: 86400

    // 加法常數折疊
    int total;
    total = 100 + 200 + 300;
    printf("Test17 100+200+300   = %d\n", total);  // 預期: 600

    // 混合加乘常數折疊
    int mixed;
    mixed = 3 * 4 + 5 * 6;
    printf("Test18 3*4+5*6       = %d\n", mixed);  // 預期: 42

    // float 常數折疊
    float fconst;
    fconst = 2.0 * 3.0;
    printf("Test19 2.0*3.0       = %f\n", fconst);  // 預期: 6.000000

    // 減法常數折疊
    int diff;
    diff = 1000 - 300 - 200;
    printf("Test20 1000-300-200  = %d\n", diff);  // 預期: 500

    // 除法常數折疊
    int quot;
    quot = 144 / 12;
    printf("Test21 144/12        = %d\n", quot);  // 預期: 12

    // 常數折疊 + 變數運算（只有常數部分被折疊）
    int x;
    x = 5;
    int combined;
    combined = x + 10 * 2;
    printf("Test22 x + 10*2      = %d\n", combined);  // 預期: 25

    return 0;
}