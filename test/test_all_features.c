// ================================================================
// test_all_features.c
// 涵蓋所有加分功能，每個功能獨立區段
// ================================================================

// ──────────────────────────────────────
// 【前置宣告 Prototype】
// ──────────────────────────────────────
int add(int a, int b);
float fadd(float a, float b);
int is_even(int n);
int is_odd(int n);

// ──────────────────────────────────────
// 【struct】
// ──────────────────────────────────────
struct Point { int x; int y; };

// ──────────────────────────────────────
// 【typedef struct】
// ──────────────────────────────────────
typedef struct Rect { int w; int h; } Rect;

// ──────────────────────────────────────
// 【enum】
// ──────────────────────────────────────
enum Color { RED, GREEN, BLUE };

// ──────────────────────────────────────
// 【#define 巨集】
// ──────────────────────────────────────
#define MAX_VAL 100
#define HALF_VAL 50

// ──────────────────────────────────────
// 【全域變數】
// ──────────────────────────────────────
int g_counter;

// ──────────────────────────────────────
// 【Prototype 對應定義（含互遞迴）】
// ──────────────────────────────────────
int add(int a, int b)   { return a + b; }
float fadd(float a, float b) { return a + b; }
int is_even(int n) { if (n == 0) { return 1; } return is_odd(n - 1); }
int is_odd(int n)  { if (n == 0) { return 0; } return is_even(n - 1); }
void inc_counter() { g_counter = g_counter + 1; }
float weighted(int v, float w) { return v * w; }
int clamp(int v, int lo, int hi) {
    if (v < lo) { return lo; }
    if (v > hi) { return hi; }
    return v;
}

int main() {

    // ════════════════════════════════
    // 1. % 運算子
    // ════════════════════════════════
    printf("=== %% operator ===\n");
    printf("%d\n",  10 %  3);   // 1
    printf("%d\n", -10 %  3);   // -1
    printf("%d\n",  10 % -3);   // 1

    // ════════════════════════════════
    // 2. ++ / -- (prefix & postfix)
    // ════════════════════════════════
    printf("=== ++ -- ===\n");
    int a; a = 5;
    printf("%d\n", a++);   // 5
    printf("%d\n", a);     // 6
    printf("%d\n", ++a);   // 7
    printf("%d\n", a);     // 7
    printf("%d\n", a--);   // 7
    printf("%d\n", a);     // 6
    printf("%d\n", --a);   // 5
    printf("%d\n", a);     // 5

    // ════════════════════════════════
    // 3. += -= *= /= %=
    // ════════════════════════════════
    printf("=== compound assign ===\n");
    int x; x = 10;
    x += 5;  printf("%d\n", x);   // 15
    x -= 3;  printf("%d\n", x);   // 12
    x *= 2;  printf("%d\n", x);   // 24
    x /= 4;  printf("%d\n", x);   // 6
    x %= 4;  printf("%d\n", x);   // 2

    // ════════════════════════════════
    // 4. 前置宣告 Prototype
    // ════════════════════════════════
    printf("=== prototype ===\n");
    printf("%d\n",   add(3, 4));       // 7
    printf("%f\n",   fadd(1.5, 2.5)); // 4.000000
    printf("%d\n",   is_even(4));      // 1
    printf("%d\n",   is_odd(3));       // 1

    // ════════════════════════════════
    // 5. for loop
    // ════════════════════════════════
    printf("=== for loop ===\n");
    int i; int s; s = 0;
    for (i = 1; i <= 5; i++) { s += i; }
    printf("%d\n", s);     // 15
    for (i = 5; i >= 1; i--) { printf("%d\n", i); } // 5 4 3 2 1

    // ════════════════════════════════
    // 6. do-while
    // ════════════════════════════════
    printf("=== do-while ===\n");
    int d; d = 0;
    do { d++; } while (d < 3);
    printf("%d\n", d);     // 3
    int e; e = 99;
    do { printf("%d\n", e); e++; } while (e < 99); // 99 (至少執行一次)

    // ════════════════════════════════
    // 7. 巢狀迴圈混用
    // ════════════════════════════════
    printf("=== nested loops ===\n");
    int sum; sum = 0;
    for (i = 1; i <= 3; i++) {
        int j; j = 1;
        while (j <= 3) {
            sum += i * j;
            j++;
        }
    }
    printf("%d\n", sum);   // 36

    // ════════════════════════════════
    // 8. switch-case
    // ════════════════════════════════
    printf("=== switch-case ===\n");
    int c; c = 2;
    switch (c) {
        case 1: printf("one\n");   break;
        case 2: printf("two\n");   break;
        case 3: printf("three\n"); break;
        default: printf("other\n"); break;
    }
    c = 9;
    switch (c) {
        case 1: printf("one\n"); break;
        default: printf("nine\n"); break;
    }
    int col; col = GREEN;
    switch (col) {
        case 0: printf("red\n");   break;
        case 1: printf("green\n"); break;
        case 2: printf("blue\n");  break;
    }

    // ════════════════════════════════
    // 9. break / continue
    // ════════════════════════════════
    printf("=== break/continue ===\n");
    i = 0;
    while (i < 10) {
        i++;
        if (i % 2 == 0) { continue; }
        if (i > 7)      { break; }
        printf("%d\n", i);   // 1 3 5 7
    }
    int ii; int jj;
    for (ii = 0; ii < 3; ii++) {
        for (jj = 0; jj < 3; jj++) {
            if (jj == 1) { break; }
            printf("%d%d\n", ii, jj);   // 00 10 20
        }
    }

    // ════════════════════════════════
    // 10. 三元運算子
    // ════════════════════════════════
    printf("=== ternary ===\n");
    int v; v = 7;
    int r; r = (v > 5) ? 1 : 0;          printf("%d\n", r);    // 1
    r = (v > 10) ? 1 : 0;                 printf("%d\n", r);    // 0
    float tf; tf = (v > 5) ? 1.5 : 2.5;  printf("%f\n", tf);   // 1.500000

    // ════════════════════════════════
    // 11. 邏輯運算子 && || !
    // ════════════════════════════════
    printf("=== logical ===\n");
    int p; p = 1; int q; q = 0;
    if (p && q) { printf("1\n"); } else { printf("0\n"); }   // 0
    if (p || q) { printf("1\n"); } else { printf("0\n"); }   // 1
    if (!p)     { printf("1\n"); } else { printf("0\n"); }   // 0
    if (!q)     { printf("1\n"); } else { printf("0\n"); }   // 1
    if (p > 0 && q == 0) { printf("yes\n"); }                // yes

    // ════════════════════════════════
    // 12. 位元運算子 & | ^ ~ << >>
    // ════════════════════════════════
    printf("=== bitwise ===\n");
    int b1; b1 = 12;   // 1100
    int b2; b2 = 10;   // 1010
    printf("%d\n", b1 & b2);   // 8
    printf("%d\n", b1 | b2);   // 14
    printf("%d\n", b1 ^ b2);   // 6
    printf("%d\n", ~b1);        // -13
    printf("%d\n", b1 << 1);   // 24
    printf("%d\n", b1 >> 1);   // 6

    // ════════════════════════════════
    // 13. 顯式型別轉換 (explicit cast)
    // ════════════════════════════════
    printf("=== explicit cast ===\n");
    float fc; fc = 3.7;
    int ic; ic = (int)fc;        printf("%d\n", ic);    // 3
    int ii2; ii2 = 7;
    float ff; ff = (float)ii2;   printf("%f\n", ff);    // 7.000000
    printf("%d\n", (int)(-2.9));                         // -2

    // ════════════════════════════════
    // 14. 隱式型別轉換
    // ════════════════════════════════
    printf("=== implicit cast ===\n");
    float fi; fi = 5;            printf("%f\n", fi);    // 5.000000
    int id2; id2 = 3.9;          printf("%d\n", id2);   // 3
    int ia; ia = 3; float fb; fb = 1.5;
    float fc2; fc2 = ia + fb;    printf("%f\n", fc2);   // 4.500000

    // ════════════════════════════════
    // 15. char 型別 + %c + 字元運算
    // ════════════════════════════════
    printf("=== char ===\n");
    char ch; ch = 'A';
    printf("%c\n", ch);          // A
    int ni; ni = ch + 1;
    printf("%d\n", ni);          // 66
    char ch2; ch2 = 65;
    printf("%c\n", ch2);         // A
    char arr[6];
    arr[0]='h'; arr[1]='e'; arr[2]='l';
    arr[3]='l'; arr[4]='o'; arr[5]='\0';
    printf("%s\n", arr);         // hello

    // ════════════════════════════════
    // 16. 一維陣列
    // ════════════════════════════════
    printf("=== 1D array ===\n");
    int nums[5];
    nums[0]=10; nums[1]=20; nums[2]=30; nums[3]=40; nums[4]=50;
    for (i = 0; i < 5; i++) { printf("%d\n", nums[i]); }

    // ════════════════════════════════
    // 17. 二維陣列
    // ════════════════════════════════
    printf("=== 2D array ===\n");
    int mat[2][3];
    mat[0][0]=1; mat[0][1]=2; mat[0][2]=3;
    mat[1][0]=4; mat[1][1]=5; mat[1][2]=6;
    printf("%d\n", mat[0][1]);   // 2
    printf("%d\n", mat[1][2]);   // 6

    // ════════════════════════════════
    // 18. struct
    // ════════════════════════════════
    printf("=== struct ===\n");
    struct Point pt;
    pt.x = 3; pt.y = 4;
    printf("%d\n", pt.x);   // 3
    printf("%d\n", pt.y);   // 4
    pt.x += 1;
    printf("%d\n", pt.x);   // 4

    // ════════════════════════════════
    // 19. typedef struct
    // ════════════════════════════════
    printf("=== typedef struct ===\n");
    Rect rc;
    rc.w = 5; rc.h = 3;
    int area; area = rc.w * rc.h;
    printf("%d\n", area);   // 15

    // ════════════════════════════════
    // 20. enum
    // ════════════════════════════════
    printf("=== enum ===\n");
    printf("%d\n", RED);    // 0
    printf("%d\n", GREEN);  // 1
    printf("%d\n", BLUE);   // 2

    // ════════════════════════════════
    // 21. #define 巨集
    // ════════════════════════════════
    printf("=== #define ===\n");
    printf("%d\n", MAX_VAL);      // 100
    printf("%d\n", HALF_VAL);     // 50
    int mx; mx = MAX_VAL + HALF_VAL;
    printf("%d\n", mx);           // 150

    // ════════════════════════════════
    // 22. 全域變數 + void 副作用
    // ════════════════════════════════
    printf("=== global var ===\n");
    g_counter = 0;
    inc_counter(); inc_counter(); inc_counter();
    printf("%d\n", g_counter);    // 3

    // ════════════════════════════════
    // 23. ## 運算子
    // ════════════════════════════════
    printf("=== ## operator ===\n");
    float ha; ha = 1.5; float hb; hb = 2.5;
    float hr; hr = ha ## hb;
    printf("%f\n", hr);    // 4.750000
    ha = 2.0; hb = 3.0;
    hr = ha ## hb;
    printf("%f\n", hr);    // 17.000000

    // ════════════════════════════════
    // 24. 作用域遮蔽
    // ════════════════════════════════
    printf("=== scope ===\n");
    int sv; sv = 1;
    { int sv; sv = 2; { int sv; sv = 3; printf("%d\n", sv); } printf("%d\n", sv); }
    printf("%d\n", sv);    // 3 2 1

    // ════════════════════════════════
    // 25. DCE（dead store + dead assign）
    // ════════════════════════════════
    printf("=== DCE ===\n");
    int dv;
    dv = 1; dv = 2; dv = 3;     // stores 1,2 eliminated
    printf("%d\n", dv);           // 3
    int du; du = 999 * 888;       // dead assignment eliminated

    return 0;
}
