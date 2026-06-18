// ── 測試 1：多行巨集（backslash-newline continuation）──

// 基本多行 object-like macro
#define BIG_VALUE \
    (100 + 200 + 300)

// 多行 function-like macro
#define MAX(a, b) \
    ((a) > (b) ? (a) : (b))

// 三行接合
#define SUM3(x, y, z) \
    ((x) \
     + (y) \
     + (z))

// 多行巨集搭配字串化
#define LOG(fmt, val) \
    printf("[LOG] " fmt "\n", val)

int main() {
    int v = BIG_VALUE;
    printf("BIG_VALUE = %d\n", v);          // 期望：600

    int a = 10, b = 20;
    int m = MAX(a, b);
    printf("MAX(10,20) = %d\n", m);          // 期望：20

    int s = SUM3(1, 2, 3);
    printf("SUM3(1,2,3) = %d\n", s);         // 期望：6

    LOG("%d", v);                             // 期望：[LOG] 600

    // 多行巨集在 #ifdef 條件內
#define SCALE(x) \
    ((x) * 3)
    printf("SCALE(7) = %d\n", SCALE(7));     // 期望：21

    return 0;
}
