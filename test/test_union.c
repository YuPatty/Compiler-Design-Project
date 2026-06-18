union FloatBits {
    float f;
    int i;
};

int main() {
    union FloatBits u;
    u.f = -1.5;
    printf("Float value: %f\n", u.f);
    // 直接印出底層的二進位表示！
    printf("Hex representation: %x\n", u.i); 
    return 0;
}