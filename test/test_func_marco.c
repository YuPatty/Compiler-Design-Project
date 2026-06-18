// test_func_macro.c

// 測試一般常數巨集
#define PI 3.14159
#define MAX_VAL 100

// 測試函式型巨集
#define SQUARE(x) ((x) * (x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))

int main() {
    int num = 5;
    
    // 測試一般替換
    printf("PI is approximately: %f\n", PI);
    printf("Max value is: %d\n", MAX_VAL);
    
    // 測試函式型巨集替換
    int sq = SQUARE(num);
    int biggest = MAX(10, 20);
    int smallest = MIN(50, 15);
    
    printf("Square of %d is: %d\n", num, sq);
    printf("Max of 10 and 20 is: %d\n", biggest);
    printf("Min of 50 and 15 is: %d\n", smallest);
    
    return 0;
}