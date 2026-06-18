// test_advanced_features.c
// 測試：常數折疊、陣列初始化、字串初始化、三元運算子、char 整數提升、隱式型別轉換

int main(void) {
    printf("--- Advanced Features Test Start ---\n");

    // 1. 常數折疊 (Constant Folding)
    int fold_int = 24 * 60 * 60;
    float fold_float = 3.14f * 2.0f;
    int fold_mod = 100 % 7;
    printf("1. Constant Folding: int=%d, float=%f, mod=%d\n", fold_int, fold_float, fold_mod);

    // 2. 陣列初始化清單
    int arr[3] = {10, 20, 30};
    float f_arr[2] = {5, 10};
    printf("2. Array Init: arr[0]=%d, arr[1]=%d, arr[2]=%d\n", arr[0], arr[1], arr[2]);
    printf("   Float Array Init: f_arr[0]=%f, f_arr[1]=%f\n", f_arr[0], f_arr[1]);

    // 3. 字串直接初始化 Char 陣列
    char str[6] = "Hello";
    printf("3. String Array Init: %s\n", str);

    // 4. 三元運算子
    int a = 15;
    int b = 20;
    int max = (a > b) ? a : b;
    printf("4. Ternary Max: %d\n", max);
    float mixed_ternary = (a < b) ? 3.14f : 100;
    printf("   Mixed Ternary: %f\n", mixed_ternary);

    // 5. Char Integer Promotion
    char c1 = 'A';
    int c_promoted = c1 + 5;
    printf("5. Char Promotion: 'A' + 5 = %d\n", c_promoted);

    // 6. 隱式型別轉換                    ← 新增
    printf("6. Implicit Type Conversion:\n");
    // int → float
    float fi = 5;
    printf("   float fi = 5  → %f\n", fi);
    // float → int（截斷）
    int it = 3.99f;
    printf("   int it = 3.99f → %d\n", it);
    // int → double
    double di = 7;
    printf("   double di = 7 → %f\n", di);
    // float + int → float
    float mixed = 1.5f + 3;
    printf("   1.5f + 3 = %f\n", mixed);
    // double + int → double（轉 float printf）
    double dmix = 2.5 + 4;
    printf("   2.5 + 4 = %f\n", (float)dmix);

    printf("--- Advanced Features Test End ---\n");
    return 0;
}
