#include <stdio.h>
#include <math.h>

// ## operator: a##b = a^b + b^a (both float)
float my_hashhash(float a, float b) {
    // powf(a, b) 會精準計算 a 的 b 次方，支援浮點數
    return powf(a, b) + powf(b, a);
}