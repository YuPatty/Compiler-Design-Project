// test_typedef.c
// 測試：typedef 型別別名

typedef int MyInt;
typedef float Real;
typedef char Byte;

typedef struct Point {
    int x;
    int y;
} Point;

typedef struct {
    float real;
    float imag;
} Complex;

MyInt add(MyInt a, MyInt b) {
    return a + b;
}

Real scale(Real val, Real factor) {
    return val * factor;
}

int main(void) {
    printf("=== 基本型別別名 ===\n");
    MyInt a;
    MyInt b;
    a = 10;
    b = 20;
    printf("MyInt: %d + %d = %d\n", a, b, add(a, b));  // 30

    Real pi;
    pi = 3.14159;
    Real r;
    r = scale(pi, 2.0);
    printf("Real: pi*2 = %f\n", r);  // 6.28318

    Byte ch;
    ch = 65;
    printf("Byte: %d\n", ch);  // 65

    printf("=== typedef struct ===\n");
    Point p1;
    p1.x = 3;
    p1.y = 4;
    printf("Point: (%d, %d)\n", p1.x, p1.y);  // (3, 4)

    // 距離計算（無 sqrt）
    int dist_sq;
    dist_sq = p1.x * p1.x + p1.y * p1.y;
    printf("dist^2 = %d\n", dist_sq);  // 25

    printf("=== 多層別名 ===\n");
    MyInt arr[5];
    int i;
    i = 0;
    while (i < 5) {
        arr[i] = i * i;
        i = i + 1;
    }
    i = 0;
    while (i < 5) {
        printf("arr[%d] = %d\n", i, arr[i]);
        i = i + 1;
    }

    return 0;
}
