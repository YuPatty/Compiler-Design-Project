// test_basic.c
// 測試：基本 80 分功能 (變數宣告、算術運算、比較運算、邏輯運算、if-else 控制流程、scanf / printf)

int main() {
    printf("--- Basic Feature Test ---\n");

    // 1. 變數宣告與讀取
    int a;
    int b;
    printf("Enter two integers (a and b): ");
    scanf("%d", &a);
    scanf("%d", &b);

    // 2. 基本算術與賦值
    int add_res;
    int sub_res;
    int mul_res;
    int div_res;
    int mod_res;

    add_res = a + b;
    sub_res = a - b;
    mul_res = a * b;
    div_res = a / b;
    mod_res = a % b;

    printf("a + b = %d\n", add_res);
    printf("a - b = %d\n", sub_res);
    printf("a * b = %d\n", mul_res);
    printf("a / b = %d\n", div_res);
    printf("a mod b = %d\n", mod_res);

    // 3. 浮點數基本運算
    float f1;
    float f2;
    f1 = 3.14f;
    f2 = 2.0f;
    float f_res;
    f_res = f1 * f2;
    printf("f1 * f2 = %f\n", f_res);

    // 4. 關係運算與 if-else 控制流程
    if (a > b) {
        printf("Result: a is strictly greater than b\n");
    } else {
        if (a == b) {
            printf("Result: a is equal to b\n");
        } else {
            printf("Result: a is strictly less than b\n");
        }
    }

    // 5. 邏輯運算 (&&, ||, !)
    int flag;
    flag = 0;
    
    if ((a != 0 && b != 0) || flag) {
        printf("Both a and b are non-zero.\n");
    }
    
    if (!(a == b)) {
        printf("a and b are different!\n");
    }

    printf("--- Test Finished ---\n");
    return 0;
}