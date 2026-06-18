// test_rubric.c
// 測試項目涵蓋：所有隱式轉型、強制轉型、複雜的 Nested 控制流、函式呼叫與最佳化

// [Function call] 測試函式
int magic_func(float x) {
    // [Explicit type casting] 強制轉型
    int truncated;
    truncated = (int)x; 
    return truncated;
}

int main() {
    printf("--- Rubric All-in-One Test ---\n");

    // 1. [Implicit Type Conversion]
    float f_val;
    // (op) int 轉 float 運算
    f_val = 10 + 3.14f; 
    
    int i_val;
    // (truncation) float 賦值給 int
    i_val = 9.99f; 
    
    float promote_val;
    // int 賦值給 float
    promote_val = i_val; 

    printf("Op float = %f, Trunc int = %d, Promote float = %f\n", f_val, i_val, promote_val);

    // 2. [Simple code optimizations] 測試 +0 與 *1 (不會產生運算指令)
    int opt_test;
    opt_test = (i_val + 0) * 1;

    // 3. 複雜控制流程測試
    int count; count = 0;
    
    // [While-loop construct]
    while (count < 2) {
        int inner; inner = 0;
        
        // [Nested while-loop construct]
        while (inner < 2) {
            
            // [While-loop construct + if construct]
            if (inner == 1) {
                
                // [Nested if construct]
                if (count == 1) {
                    // [Function call]
                    int func_res;
                    func_res = magic_func(42.8f);
                    printf("Deepest level reached! Func res = %d\n", func_res);
                } else {
                    printf("Inner loop matching...\n");
                }
            }
            inner++;
        }
        count++;
    }

    printf("Optimized value = %d\n", opt_test);
    printf("--- Test End ---\n");
    return 0;
}