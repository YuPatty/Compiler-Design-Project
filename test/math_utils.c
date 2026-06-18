// ════════════════════════════════════════
// math_utils.c — 第二個編譯單元
// 這個檔案單獨編譯成 math_utils.ll
// ════════════════════════════════════════

int add(int a, int b) {
    return a + b;
}

int multiply(int a, int b) {
    return a * b;
}

double power(double base, int exp) {
    double result = 1.0;
    int i;
    for (i = 0; i < exp; i++) {
        result = result * base;
    }
    return result;
}

int global_counter = 0;

void increment_counter(void) {
    global_counter = global_counter + 1;
}

int get_counter(void) {
    return global_counter;
}
