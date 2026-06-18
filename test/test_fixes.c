// 綜合測試：驗證三項修正
// 1. 負數整數除法/取模（修正前 ashr 強度削減錯誤）
// 2. 比較結果參與 * / 運算（修正前缺少 i1->i32 zext）
// 3. if-else 兩分支皆 return 時不應誤報「遺漏回傳值」警告

int classify(int n) {
    if (n > 0) {
        return 1;
    } else {
        return -1;
    }
}

int main() {
    // --- 修正1：負數除法/取模 ---
    printf("-7/2 = %d\n", -7 / 2);
    printf("-5/2 = %d\n", -5 / 2);
    printf("-1/2 = %d\n", -1 / 2);
    printf("(3-8)/2 = %d\n", (3 - 8) / 2);
    printf("-7%%2 = %d\n", -7 % 2);

    int a, b;
    a = -10; b = 5;
    int z;
    z = a + b * 2 - (a - b) / 2;
    printf("z = %d\n", z);

    // --- 修正2：比較結果參與 * / ---
    a = 2;
    printf("(a==2)*100 = %d\n", (a == 2) * 100);
    printf("(a==2)/1 = %d\n", (a == 2) / 1);

    int c, d;
    c = 4; d = 5;
    printf("(a<5)*(c<d) = %d\n", (a < 5) * (c < d));

    // --- 修正3：if-else 兩分支皆 return（不應有警告）---
    printf("classify(5) = %d\n", classify(5));
    printf("classify(-5) = %d\n", classify(-5));

    return 0;
}
