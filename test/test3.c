// test3.c
// 測試：float、## 運算子、隱式/顯式型別轉換

int main() {
    float a;
    float b;
    a = 1.5f;
    b = 2.5f;

    // ## 運算子：a##b = a^b + b^a
    float result;
    result = a ## b;
    printf("1.5 ## 2.5 = %f\n", result);

    // ## 與加法混合（## 優先權同 * /，比 + 高）
    float c;
    c = a ## b + 1.0f;
    printf("(1.5##2.5) + 1.0 = %f\n", c);

    // 隱式型別轉換：int op float
    int x;
    x = 3;
    float y;
    y = x + 2.5f;
    printf("3 + 2.5 = %f\n", y);

    // 隱式轉換：float 指派給 int（截斷）
    int truncated;
    truncated = 3.9f;
    printf("3.9 truncated to int = %d\n", truncated);

    // 隱式轉換：int 指派給 float
    float promoted;
    promoted = 7;
    printf("7 as float = %f\n", promoted);

    // 顯式型別轉換
    float pi;
    pi = 3.14159f;
    int pi_int;
    pi_int = (int)pi;
    printf("(int)3.14159 = %d\n", pi_int);

    // scanf float
    float input;
    printf("Enter a float: ");
    scanf("%f", &input);
    float doubled;
    doubled = input * 2.0f;
    printf("Doubled: %f\n", doubled);

    return 0;
}