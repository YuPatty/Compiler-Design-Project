/* =====================================================
   test_type_system.c
   一、型別系統與資料結構
   ===================================================== */

/* ── 全域 struct ── */
struct Point {
    int x;
    int y;
};

struct Rectangle {
    float w;
    float h;
};

/* ── typedef ── */
typedef int MyInt;
typedef float Real;
typedef struct Point Point;

/* ── enum ── */
enum Color { RED, GREEN, BLUE };
enum Status { OK = 0, WARN = 10, ERR = 99 };

int main(void) {

    /* ---------------------------------------------------
       1. double 型別
       --------------------------------------------------- */
    printf("--- 1. double ---\n");
    double d1;
    double d2;
    d1 = 3.14159265358979;
    d2 = 2.71828182845905;
    printf("d1 = %f\n", d1);
    printf("d2 = %f\n", d2);
    printf("d1+d2 = %f\n", d1 + d2);
    printf("d1*d2 = %f\n", d1 * d2);

    double dz;
    dz = 0.0;
    if (dz == 0.0) printf("dz==0.0 OK\n");

    /* ---------------------------------------------------
       2. bool / true / false
       --------------------------------------------------- */
    printf("--- 2. bool ---\n");
    int t;
    int f;
    t = true;
    f = false;
    printf("true = %d\n", t);
    printf("false = %d\n", f);

    if (true)  printf("if(true) OK\n");
    if (!false) printf("if(!false) OK\n");

    int x;
    x = 5;
    int bt;
    bt = (x > 3);
    printf("(5>3) = %d\n", bt);
    bt = (x > 10);
    printf("(5>10) = %d\n", bt);

    /* ---------------------------------------------------
       3. 一維陣列 + 初始化清單
       --------------------------------------------------- */
    printf("--- 3. 1D array ---\n");
    int arr1[5];
    arr1[0] = 10;
    arr1[1] = 20;
    arr1[2] = 30;
    arr1[3] = 40;
    arr1[4] = 50;
    printf("arr1[0]=%d arr1[4]=%d\n", arr1[0], arr1[4]);

    float farr[3];
    farr[0] = 1.1;
    farr[1] = 2.2;
    farr[2] = 3.3;
    printf("farr[1]=%f\n", farr[1]);

    int sum;
    sum = 0;
    int i;
    i = 0;
    while (i < 5) {
        sum = sum + arr1[i];
        i = i + 1;
    }
    printf("sum=%d\n", sum);

    /* ---------------------------------------------------
       4. 二維陣列 int a[3][4]
       --------------------------------------------------- */
    printf("--- 4. 2D array ---\n");
    int mat[3][4];
    int r;
    int c;
    r = 0;
    while (r < 3) {
        c = 0;
        while (c < 4) {
            mat[r][c] = r * 4 + c;
            c = c + 1;
        }
        r = r + 1;
    }
    printf("mat[0][0]=%d\n", mat[0][0]);
    printf("mat[1][2]=%d\n", mat[1][2]);
    printf("mat[2][3]=%d\n", mat[2][3]);

    /* ---------------------------------------------------
       5. char 純量、char 陣列、字串字面值
       --------------------------------------------------- */
    printf("--- 5. char ---\n");
    char ch;
    ch = 'A';
    printf("ch = %c\n", ch);

    char str1[32];
    str1 = "Hello, World!";
    printf("%s\n", str1);

    char str2[32];
    str2 = "LLVM compiler";
    printf("%s\n", str2);

    /* ---------------------------------------------------
       6. 字串字面值直接賦值 s = "hello"
       --------------------------------------------------- */
    printf("--- 6. string assign ---\n");
    char buf[64];
    buf = "first assignment";
    printf("buf = %s\n", buf);
    buf = "second assignment";
    printf("buf = %s\n", buf);
    buf = "line with newline";
    printf("buf = %s\n", buf);

    /* ---------------------------------------------------
       7. struct / typedef struct
       --------------------------------------------------- */
    printf("--- 7. struct ---\n");
    struct Point p;
    p.x = 10;
    p.y = 20;
    printf("p.x=%d p.y=%d\n", p.x, p.y);
    p.x = p.x + 5;
    printf("p.x+5=%d\n", p.x);

    struct Rectangle rect;
    rect.w = 3.0;
    rect.h = 4.0;
    printf("area=%f\n", rect.w * rect.h);

    Point tp;
    tp.x = 100;
    tp.y = 200;
    printf("tp.x=%d tp.y=%d\n", tp.x, tp.y);

    MyInt mi;
    mi = 42;
    printf("MyInt mi=%d\n", mi);

    Real rr;
    rr = 2.718;
    printf("Real rr=%f\n", rr);

    /* ---------------------------------------------------
       8. enum（含自訂值）
       --------------------------------------------------- */
    printf("--- 8. enum ---\n");
    printf("RED=%d GREEN=%d BLUE=%d\n", RED, GREEN, BLUE);
    printf("OK=%d WARN=%d ERR=%d\n", OK, WARN, ERR);

    int color;
    color = GREEN;
    if (color == GREEN) printf("color is GREEN\n");

    int status;
    status = ERR;
    if (status == 99) printf("status is ERR(99)\n");

    /* ---------------------------------------------------
       9. sizeof(type) / sizeof(expr)
       --------------------------------------------------- */
    printf("--- 9. sizeof ---\n");
    int si;
    int sf;
    int sd;
    int sc;
    si = sizeof(int);
    sf = sizeof(float);
    sd = sizeof(double);
    sc = sizeof(char);
    printf("sizeof(int)=%d\n", si);
    printf("sizeof(float)=%d\n", sf);
    printf("sizeof(double)=%d\n", sd);
    printf("sizeof(char)=%d\n", sc);

    int n;
    n = 42;
    int sn;
    sn = sizeof(n);
    printf("sizeof(n)=%d\n", sn);

    /* ---------------------------------------------------
       10. 指標（pointer）
       --------------------------------------------------- */
    printf("--- 10. pointer ---\n");
    int a;
    a = 99;
    int *pa;
    pa = &a;
    printf("a=%d\n", a);
    printf("*pa=%d\n", *pa);
    *pa = 123;
    printf("a after *pa=123: %d\n", a);

    float fval;
    fval = 3.14;
    float *pf;
    pf = &fval;
    printf("*pf=%f\n", *pf);
    *pf = 6.28;
    printf("fval after *pf=6.28: %f\n", fval);

    return 0;
}
