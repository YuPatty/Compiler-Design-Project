// test6.c
// 測試：複雜的算術運算、浮點數與整數混合運算、## 運算子、if-else、scanf/printf

float calculateEnergy(float mass, float velocity) {
    // 測試函式回傳值與連續乘法
    return 0.5f * mass * velocity * velocity;
}

int main() {
    int id;
    float base_val;
    float exp_val;

    printf("Enter ID (int): ");
    scanf("%d", &id);

    printf("Enter base and exp (float): ");
    scanf("%f", &base_val);
    scanf("%f", &exp_val);

    // ## 運算子測試 (a^b + b^a)
    float magic_power;
    magic_power = base_val ## exp_val;
    printf("Magic Power (base ## exp) = %f\n", magic_power);

    // 隱式轉型與函式呼叫
    float energy;
    // 傳入 10.0 和 5.0，計算 0.5 * 10 * 5 * 5 = 125.0
    energy = calculateEnergy(10.0f, 5.0f); 
    printf("Base Energy = %f\n", energy);

    // 複雜條件比較 (包含 float 比較與 AND 邏輯)
    if (magic_power > energy && id != 0) {
        printf("Status: HIGH POWER\n");
    } else {
        if (magic_power == energy) {
            printf("Status: EQUAL POWER\n");
        } else {
            printf("Status: NORMAL\n");
        }
    }

    // 確保餘數運算正常 (只有 int 可以用)
    int remainder;
    remainder = id % 3;
    printf("ID mod 3 = %d\n", remainder);

    return 0;
}