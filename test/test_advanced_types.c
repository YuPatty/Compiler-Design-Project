// test_advanced_types.c
// 測試：double、bool/true/false、多變數同行宣告、科學記號
//       char 整數提升、char 陣列與字串初始化、void return、DCE、Strength Reduction

void say_hi(void) {
    printf("Hi from void function!\n");
    return;
}

void greet(int n) {
    if (n > 0) {
        printf("Positive greeting!\n");
        return;
    }
    printf("Non-positive greeting!\n");
}

int main(void) {

    // ════════════════════════════════
    // 1. double 型別
    // ════════════════════════════════
    printf("=== double ===\n");
    double d1; d1 = 3.141592653589793;
    double d2; d2 = 2.718281828459045;
    printf("pi  = %f\n", (float)d1);
    printf("e   = %f\n", (float)d2);
    double d3; d3 = d1 + d2;
    printf("pi+e= %f\n", (float)d3);

    // ════════════════════════════════
    // 2. bool / true / false
    // ════════════════════════════════
    printf("=== bool ===\n");
    bool bt; bt = true;
    bool bf; bf = false;
    printf("true=%d false=%d\n", bt, bf);
    bool br1; br1 = (5 > 3);
    bool br2; br2 = (5 < 3);
    printf("5>3=%d 5<3=%d\n", br1, br2);
    if (bt)  printf("bt is true\n");
    if (!bf) printf("bf is false\n");

    // ════════════════════════════════
    // 3. 多變數同行宣告（含初始值）
    // ════════════════════════════════
    printf("=== multi-var decl ===\n");
    int a = 1, b = 2, c = 3;
    printf("a=%d b=%d c=%d\n", a, b, c);
    float fx = 1.5, fy = 2.5, fz = 3.0;
    printf("fx=%f fy=%f fz=%f\n", fx, fy, fz);
    int p = 5, q = p + 3;
    printf("p=%d q=%d\n", p, q);

    // ════════════════════════════════
    // 4. 科學記號浮點數
    // ════════════════════════════════
    printf("=== scientific ===\n");
    float s1; s1 = 1.5e2;
    float s2; s2 = 2.0E-1;
    float s3; s3 = 3.14f;
    float s4; s4 = 1e3;
    printf("1.5e2=%f 2.0E-1=%f 3.14f=%f 1e3=%f\n", s1, s2, s3, s4);

    // ════════════════════════════════
    // 5. char 整數提升
    // ════════════════════════════════
    printf("=== char promotion ===\n");
    char ch; ch = 65;
    int promoted; promoted = ch + 0;
    printf("char 65 promoted=%d\n", promoted);
    char next; next = ch + 1;
    printf("A+1=%d\n", next);

    // ════════════════════════════════
    // 6. char 陣列與字串初始化      ← 新增
    // ════════════════════════════════
    printf("=== char array ===\n");
    char s1c[6] = "Hello";
    printf("s1c = %s\n", s1c);
    char s2c[4];
    s2c[0] = 'C'; s2c[1] = 'a'; s2c[2] = 't'; s2c[3] = 0;
    printf("s2c = %s\n", s2c);
    char s3c[] = "World";
    printf("s3c = %s\n", s3c);
    // char 陣列參與整數運算
    int cv = s1c[0] + 1;
    printf("s1c[0]+1 = %d\n", cv);

    // ════════════════════════════════
    // 7. void return
    // ════════════════════════════════
    printf("=== void return ===\n");
    say_hi();
    greet(5);
    greet(-1);

    // ════════════════════════════════
    // 8. DCE if(1) / if(0)
    // ════════════════════════════════
    printf("=== DCE if(1)/if(0) ===\n");
    if (1) {
        printf("if(1) taken\n");
    } else {
        printf("DEAD - must not appear in IR\n");
    }
    if (0) {
        printf("DEAD - must not appear in IR\n");
    } else {
        printf("if(0) else taken\n");
    }

    // ════════════════════════════════
    // 9. Strength Reduction
    // ════════════════════════════════
    printf("=== Strength Reduction ===\n");
    int n; n = 10;
    int sr1; sr1 = n * 2;
    int sr2; sr2 = n * 4;
    int sr3; sr3 = n * 8;
    int sr4; sr4 = n / 2;
    int sr5; sr5 = n / 4;
    printf("n*2=%d n*4=%d n*8=%d n/2=%d n/4=%d\n", sr1, sr2, sr3, sr4, sr5);
    int sr6; sr6 = n * 3;
    int sr7; sr7 = n / 3;
    printf("n*3=%d n/3=%d\n", sr6, sr7);

    // ════════════════════════════════
    // 10. 字串常數池去重
    // ════════════════════════════════
    printf("=== String Pooling ===\n");
    printf("hello world\n");
    printf("hello world\n");
    printf("hello world\n");

    printf("=== escape ===\n");
    printf("tab:\there\n");
    printf("quote: \"hi\"\n");

    return 0;
}
