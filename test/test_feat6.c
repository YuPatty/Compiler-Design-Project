// test_6features.c
// 測試：for宣告式初始化、strcat/strcmp、math.h、多變數宣告、enum、sizeof

// ── 功能 5：enum 定義 ──
enum Direction { NORTH, SOUTH, EAST, WEST };
enum Status { OK=200, NOT_FOUND=404, ERROR=500 };

int main(void) {

    // ── 功能 1：for 迴圈宣告型初始化 ──
    printf("=== for-init ===\n");
    int sum;
    sum = 0;
    for (int i = 0; i < 5; i++) {
        sum = sum + i;
    }
    printf("sum(0..4) = %d\n", sum);  // 10

    // 確認 i 不洩漏到外層（若洩漏會重複宣告錯誤）
    int i;
    i = 99;
    printf("i after for = %d\n", i);  // 99

    // ── 功能 4：多變數同行宣告（帶初始值）──
    printf("=== multi-var ===\n");
    int a = 1, b = 2, c = 3;
    printf("a=%d b=%d c=%d\n", a, b, c);  // 1 2 3

    float fx = 1.5, fy = 2.5;
    printf("fx=%f fy=%f\n", fx, fy);  // 1.5 2.5

    // ── 功能 6：sizeof ──
    printf("=== sizeof ===\n");
    printf("sizeof(int)    = %d\n", sizeof(int));     // 4
    printf("sizeof(float)  = %d\n", sizeof(float));   // 4
    printf("sizeof(double) = %d\n", sizeof(double));  // 8
    printf("sizeof(char)   = %d\n", sizeof(char));    // 1
    int sz;
    sz = sizeof(a);
    printf("sizeof(a)      = %d\n", sz);  // 4

    // ── 功能 5：enum 使用 ──
    printf("=== enum ===\n");
    printf("NORTH=%d SOUTH=%d\n", NORTH, SOUTH);   // 0 1
    printf("EAST=%d  WEST=%d\n",  EAST,  WEST);    // 2 3
    printf("OK=%d NOT_FOUND=%d ERROR=%d\n", OK, NOT_FOUND, ERROR);  // 200 404 500

    int dir;
    dir = EAST;
    if (dir == EAST) {
        printf("Going EAST\n");
    }

    // ── 功能 2：strcat / strcmp ──
    printf("=== string ===\n");
    char s1[32];
    char s2[32];
    char s3[64];

    // 建立字串
    s1[0] = 72; s1[1] = 101; s1[2] = 108;
    s1[3] = 108; s1[4] = 111; s1[5] = 0;   // "Hello"
    s2[0] = 32; s2[1] = 87; s2[2] = 111;
    s2[3] = 114; s2[4] = 108; s2[5] = 100; s2[6] = 0;  // " World"

    // strcpy + strcat
    strcpy(s3, s1);
    strcat(s3, s2);
    printf("strcat: %s\n", s3);  // Hello World

    // strcmp
    int cmp;
    cmp = strcmp(s1, s1);
    printf("strcmp same: %d\n", cmp);  // 0

    // ── 功能 3：math.h ──
    printf("=== math ===\n");
    float sq;
    sq = sqrt(16.0);
    printf("sqrt(16) = %f\n", sq);   // 4.0

    float pw;
    pw = pow(2.0, 10.0);
    printf("pow(2,10) = %f\n", pw);  // 1024.0

    float ab;
    ab = fabs(-3.14);
    printf("fabs(-3.14) = %f\n", ab); // 3.14

    float fl;
    fl = floor(3.7);
    printf("floor(3.7) = %f\n", fl);  // 3.0

    float cl;
    cl = ceil(3.2);
    printf("ceil(3.2) = %f\n", cl);   // 4.0

    return 0;
}
