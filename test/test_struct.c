// test_struct.c
// 測試：struct 定義、成員存取、typedef struct、struct 當函式參數

struct Point {
    int x;
    int y;
};

struct Rectangle {
    int width;
    int height;
};

typedef struct {
    float real;
    float imag;
} Complex;

int point_distance_sq(struct Point p) {
    return p.x * p.x + p.y * p.y;
}

int rect_area(struct Rectangle r) {
    return r.width * r.height;
}

int rect_perimeter(struct Rectangle r) {
    return 2 * (r.width + r.height);
}

int main(void) {
    printf("=== struct 基本操作 ===\n");
    struct Point p1;
    p1.x = 3;
    p1.y = 4;
    printf("p1 = (%d, %d)\n", p1.x, p1.y);  // (3, 4)
    printf("dist^2 = %d\n", point_distance_sq(p1));  // 25

    printf("=== struct 成員修改 ===\n");
    p1.x = 10;
    p1.y = 0;
    printf("p1 modified = (%d, %d)\n", p1.x, p1.y);  // (10, 0)

    printf("=== 多個 struct 變數 ===\n");
    struct Rectangle r1;
    struct Rectangle r2;
    r1.width = 5; r1.height = 3;
    r2.width = 8; r2.height = 4;
    printf("r1 area = %d\n", rect_area(r1));          // 15
    printf("r2 area = %d\n", rect_area(r2));          // 32
    printf("r1 perimeter = %d\n", rect_perimeter(r1)); // 16
    printf("r2 perimeter = %d\n", rect_perimeter(r2)); // 24

    printf("=== typedef struct ===\n");
    Complex c1;
    c1.real = 3.0;
    c1.imag = 4.0;
    printf("c1 = %.1f + %.1fi\n", c1.real, c1.imag);  // 3.0 + 4.0i

    // 模數（magnitude）
    float mag_sq;
    mag_sq = c1.real * c1.real + c1.imag * c1.imag;
    printf("|c1|^2 = %f\n", mag_sq);  // 25.000000

    printf("=== struct 成員連算 ===\n");
    struct Rectangle big;
    big.width = r1.width + r2.width;   // 13
    big.height = r1.height + r2.height; // 7
    printf("big = %dx%d area=%d\n", big.width, big.height, rect_area(big));
    // 13x7 area=91

    return 0;
}
