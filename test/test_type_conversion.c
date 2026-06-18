// test_type_conversion.c
// 測試：隱式型別轉換（int↔float/double）、顯式強制轉型、負數截斷

int main(void) {
    printf("=== 隱式轉換：int op float → float ===\n");
    int   i; i = 5;
    float f; f = 2.5;
    float r1; r1 = i + f;   // sitofp i→5.0, fadd
    float r2; r2 = i * f;
    printf("5 + 2.5 = %f\n", r1);  // 7.500000
    printf("5 * 2.5 = %f\n", r2);  // 12.500000

    printf("=== 隱式轉換：float → int（截斷）===\n");
    float pi; pi = 3.99;
    int trunc_pi; trunc_pi = pi;    // fptosi，不四捨五入
    printf("(int)3.99 = %d\n", trunc_pi);  // 3，非 4

    float neg; neg = -2.7;
    int trunc_neg; trunc_neg = neg; // 截斷朝向 0
    printf("(int)-2.7 = %d\n", trunc_neg); // -2，非 -3

    printf("=== 隱式轉換：int → float（提升）===\n");
    int a; a = 7;
    float fa; fa = a;   // sitofp
    printf("int 7 → float: %f\n", fa);  // 7.000000

    printf("=== 顯式轉型：(int) (float) (char) ===\n");
    float x; x = 9.9;
    int xi; xi = (int)x;
    printf("(int)9.9 = %d\n", xi);       // 9

    int y; y = 65;
    char yc; yc = (char)y;
    int back; back = (int)yc;
    printf("(char)65 → (int) = %d\n", back);  // 65

    float z; z = 3.14;
    double dz; dz = (double)z;  // 精確度提升
    printf("(double)3.14 OK\n");

    printf("=== 函式參數隱式轉換 ===\n");
    // printf 的 float 參數自動升為 double（varargs）
    float ff; ff = 1.5;
    printf("float via printf: %f\n", ff);  // 1.500000

    printf("=== 混合運算鏈 ===\n");
    int p; p = 3;
    float q; q = 1.5;
    float chain; chain = p * 2 + q * 3.0 - 1;
    // 3*2=6 (int), q*3.0=4.5 (float), 6+4.5=10.5, -1 → 9.5
    printf("3*2 + 1.5*3.0 - 1 = %f\n", chain);  // 9.500000

    return 0;
}
