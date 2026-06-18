// ============================================================
// test_uint_float.c
// ============================================================
#include <stdio.h>

float uint_to_float(unsigned int u) {
    // 💡 加上 (float)，強迫編譯器去走「顯式轉型」的程式碼分支
    float f = (float)u; 
    return f;
}

unsigned int float_to_uint(float f) {
    // 💡 加上 (unsigned int)，強迫走顯式的整數截斷分支
    unsigned int v = (unsigned int)f; 
    return v;
}

int main(void) {
    unsigned int start_val = 300;
    float f = uint_to_float(start_val);
    unsigned int v = float_to_uint(f);

    printf("%f %u\n", f, v);
    return 0;
}