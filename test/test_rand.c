// test_rand.c
#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("=== Standalone Test: rand & srand ===\n");
    
    // 設定固定的種子
    unsigned int seed = 2026;
    srand(seed);
    
    // 產生第一次的亂數序列
    int r1 = rand() % 100;
    int r2 = rand() % 100;
    int r3 = rand() % 100;
    
    printf("First sequence (seed=%u): %d, %d, %d\n", seed, r1, r2, r3);
    
    // 重新設定一模一樣的種子，驗證編譯器是否有正確呼叫 void srand(i32)
    srand(seed);
    
    // 產生第二次的亂數序列
    int r4 = rand() % 100;
    int r5 = rand() % 100;
    
    printf("Second sequence (reset seed): %d, %d\n", r4, r5);
    
    // 驗證邏輯
    if (r1 == r4 && r2 == r5) {
        printf("-> Success: rand sequence matched after srand reset!\n");
    } else {
        printf("-> Failed: sequences do not match.\n");
    }
    
    return 0;
}