/* test2_scanf_printf.c
   測試項目:
   - scanf %d %f 讀取
   - printf %d %f 輸出 (單參數 / 雙參數)
   - printf 純字串 (無變數)
   - int 與 float 變數各自運算後輸出
   - if-then-else 根據輸入做不同輸出
*/

int main() {
    int n;
    float f;
    int result_i;
    float result_f;

    /* --- printf 單參數 (純字串) --- */
    printf("Hello\n");
    printf("=== scanf/printf test ===\n");

    /* --- 讀入 int --- */
    printf("Enter an integer: \n");
    scanf("%d", &n);
    printf("You entered: %d\n", n);

    /* 對輸入做運算 */
    result_i = n * 2;
    printf("n * 2 = %d\n", result_i);

    result_i = n + 100;
    printf("n + 100 = %d\n", result_i);

    result_i = n / 2;
    printf("n / 2 = %d\n", result_i);

    /* --- 讀入 float --- */
    printf("Enter a float: \n");
    scanf("%f", &f);
    printf("You entered: %f\n", f);

    result_f = f * 2.0;
    printf("f * 2.0 = %f\n", result_f);

    result_f = f + 1.5;
    printf("f + 1.5 = %f\n", result_f);

    /* --- if-then-else 根據輸入 --- */
    if (n > 0)
        printf("n is positive\n");
    else
        printf("n is non-positive\n");

    if (n == 0)
        printf("n is zero\n");
    else
        printf("n is not zero\n");

    if (f > 0.0)
        printf("f is positive\n");
    else
        printf("f is non-positive\n");

    /* --- 比較 int 與 float (分開比較) --- */
    if (n > 10)
        printf("n > 10\n");
    else
        printf("n <= 10\n");

    if (f >= 5.0)
        printf("f >= 5.0\n");
    else
        printf("f < 5.0\n");

    /* --- printf 純字串結尾 --- */
    printf("Done.\n");

    return 0;
}
