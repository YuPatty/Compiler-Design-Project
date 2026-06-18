// test_const.c
// 測試：const 常數變數（防寫保護）

const int MAX_SIZE = 100;
const float PI = 3.14159;
const int DAYS_PER_YEAR = 365;

int circle_area_int(int r) {
    // 使用全域 const
    return (int)(PI * r * r);
}

int main(void) {
    printf("=== 全域 const 讀取 ===\n");
    printf("MAX_SIZE     = %d\n", MAX_SIZE);         // 100
    printf("PI           = %f\n", PI);               // 3.141590
    printf("DAYS_PER_YEAR= %d\n", DAYS_PER_YEAR);   // 365

    printf("=== const 在運算中 ===\n");
    int half_year;
    half_year = DAYS_PER_YEAR / 2;
    printf("half year = %d\n", half_year);           // 182

    float circumference;
    circumference = 2.0 * PI * 5.0;
    printf("circumference(r=5) = %f\n", circumference); // 31.415899

    printf("=== const 在函式中使用 ===\n");
    printf("circle_area(10) = %d\n", circle_area_int(10)); // 314

    printf("=== 區域 const ===\n");
    const int LOCAL_MAX = 50;
    printf("LOCAL_MAX = %d\n", LOCAL_MAX);  // 50

    printf("=== const 作為陣列大小基準 ===\n");
    int arr[100];  // 用 MAX_SIZE 的值
    int i;
    i = 0;
    while (i < 5) {
        arr[i] = i * MAX_SIZE;
        i = i + 1;
    }
    i = 0;
    while (i < 5) {
        printf("arr[%d] = %d\n", i, arr[i]);  // 0 100 200 300 400
        i = i + 1;
    }

    return 0;
}
