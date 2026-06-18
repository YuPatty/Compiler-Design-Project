// test_verify_80pts.c
// 全自動驗證 80 分基本要求，無需 stdin
// 每個 PASS/FAIL 自動判斷並輸出

int total_pass;
int total_fail;

void check_int(int expected, int actual, int id) {
    if (expected == actual) {
        printf("[PASS] case %d: got %d\n", id, actual);
        total_pass = total_pass + 1;
    } else {
        printf("[FAIL] case %d: expected %d, got %d\n", id, expected, actual);
        total_fail = total_fail + 1;
    }
}

void check_float(float expected, float actual, int id) {
    float diff;
    diff = expected - actual;
    if (diff < 0.0f) diff = 0.0f - diff;
    if (diff < 0.001f) {
        printf("[PASS] case %d: got %f\n", id, actual);
        total_pass = total_pass + 1;
    } else {
        printf("[FAIL] case %d: expected %f, got %f\n", id, expected, actual);
        total_fail = total_fail + 1;
    }
}

int main(void) {
    total_pass = 0;
    total_fail = 0;

    // ════════════════════════════════════════════════
    // 1. 資料型別：int
    // ════════════════════════════════════════════════
    printf("=== 1. int type ===\n");
    int i1; i1 = 42;
    int i2; i2 = -99;
    int i3; i3 = 0;
    int i4; i4 = 2147483647;
    int i5; i5 = -2147483648;
    check_int(42,         i1, 101);
    check_int(-99,        i2, 102);
    check_int(0,          i3, 103);
    check_int(2147483647, i4, 104);
    check_int(-2147483648,i5, 105);

    // ════════════════════════════════════════════════
    // 2. 資料型別：float
    // ════════════════════════════════════════════════
    printf("=== 2. float type ===\n");
    float f1; f1 = 3.14f;
    float f2; f2 = -2.5f;
    float f3; f3 = 0.0f;
    float f4; f4 = 1000000.0f;
    check_float(3.14f,      f1, 201);
    check_float(-2.5f,      f2, 202);
    check_float(0.0f,       f3, 203);
    check_float(1000000.0f, f4, 204);

    // ════════════════════════════════════════════════
    // 3. 算術運算：+ - * /
    // ════════════════════════════════════════════════
    printf("=== 3. int arithmetic ===\n");
    int a; a = 10;
    int b; b = 3;
    check_int(13,  a + b, 301);
    check_int(7,   a - b, 302);
    check_int(30,  a * b, 303);
    check_int(3,   a / b, 304);
    check_int(201, b + 2 * (100 - 1), 305);  // b + 2*(100-1) = 3+198 = 201

    // 邊界：負數
    int na; na = -5;
    int nb; nb = -3;
    check_int(-8, na + nb, 306);
    check_int(-2, na - nb, 307);
    check_int(15, na * nb, 308);
    check_int(1,  na / nb, 309);

    // 零
    int z; z = 0;
    check_int(0,  z + 0,   310);
    check_int(0,  z * 999, 311);
    check_int(0,  z - 0,   312);

    printf("=== 3b. float arithmetic ===\n");
    float x; x = 6.0f;
    float y; y = 2.0f;
    check_float(8.0f,  x + y, 321);
    check_float(4.0f,  x - y, 322);
    check_float(12.0f, x * y, 323);
    check_float(3.0f,  x / y, 324);

    float fx; fx = -1.5f;
    float fy; fy = 0.5f;
    check_float(-1.0f, fx + fy, 325);
    check_float(-2.0f, fx - fy, 326);
    check_float(-0.75f,fx * fy, 327);
    check_float(-3.0f, fx / fy, 328);

    // ════════════════════════════════════════════════
    // 4. 比較運算：> >= < <= == !=
    // ════════════════════════════════════════════════
    printf("=== 4. comparison (int) ===\n");
    int m; m = 5;
    int n; n = 3;
    int r;
    r = (m > n);   check_int(1, r, 401);
    r = (m >= n);  check_int(1, r, 402);
    r = (n < m);   check_int(1, r, 403);
    r = (n <= m);  check_int(1, r, 404);
    r = (m == 5);  check_int(1, r, 405);
    r = (m != n);  check_int(1, r, 406);
    r = (m == n);  check_int(0, r, 407);
    r = (m > m);   check_int(0, r, 408);
    r = (m >= m);  check_int(1, r, 409);
    r = (m <= m);  check_int(1, r, 410);
    r = (m != m);  check_int(0, r, 411);

    // 負數比較
    r = (-1 < 0);  check_int(1, r, 412);
    r = (-1 > 0);  check_int(0, r, 413);
    r = (-1 == -1);check_int(1, r, 414);

    printf("=== 4b. comparison (float) ===\n");
    float fa; fa = 1.5f;
    float fb; fb = 2.5f;
    r = (fa < fb);  check_int(1, r, 421);
    r = (fa <= fb); check_int(1, r, 422);
    r = (fb > fa);  check_int(1, r, 423);
    r = (fb >= fa); check_int(1, r, 424);
    fa = 1.5f; fb = 1.5f;
    r = (fa == fb); check_int(1, r, 425);
    r = (fa != fb); check_int(0, r, 426);

    // ════════════════════════════════════════════════
    // 5. if-then
    // ════════════════════════════════════════════════
    printf("=== 5. if-then ===\n");
    int v; v = 7;
    int hit; hit = 0;
    if (v > 0) hit = 1;
    check_int(1, hit, 501);

    hit = 0;
    if (v > 100) hit = 1;
    check_int(0, hit, 502);

    hit = 0;
    if (v == 7) hit = 1;
    check_int(1, hit, 503);

    hit = 0;
    if (v != 7) hit = 1;
    check_int(0, hit, 504);

    // ════════════════════════════════════════════════
    // 6. if-then-else
    // ════════════════════════════════════════════════
    printf("=== 6. if-then-else ===\n");
    int res;

    res = 0;
    if (v > 10) { res = 1; } else { res = 2; }
    check_int(2, res, 601);

    res = 0;
    if (v > 0) { res = 1; } else { res = 2; }
    check_int(1, res, 602);

    res = 0;
    if (v == 0) { res = 10; } else { res = 20; }
    check_int(20, res, 603);

    // ════════════════════════════════════════════════
    // 7. 巢狀 if（3 層）
    // ════════════════════════════════════════════════
    printf("=== 7. nested if ===\n");
    int q; q = 5;
    int depth;

    depth = 0;
    if (q > 0) {
        depth = 1;
        if (q > 3) {
            depth = 2;
            if (q > 7) {
                depth = 3;
            }
        }
    }
    check_int(2, depth, 701);   // q=5: >0 yes, >3 yes, >7 no → depth=2

    q = 10;
    depth = 0;
    if (q > 0) {
        depth = 1;
        if (q > 3) {
            depth = 2;
            if (q > 7) {
                depth = 3;
            }
        }
    }
    check_int(3, depth, 702);   // q=10: 全部 yes → depth=3

    q = -1;
    depth = 0;
    if (q > 0) {
        depth = 1;
    }
    check_int(0, depth, 703);   // q=-1: 第一層不進 → depth=0

    // ════════════════════════════════════════════════
    // 8. printf 格式：%d %f（不 check stdout 格式，只確認不 crash）
    //    用計算結果驗證 printf 參數正確
    // ════════════════════════════════════════════════
    printf("=== 8. printf ===\n");
    printf("Hello\n");
    printf("Number is %d\n", 42);
    printf("Float is %f\n", 3.14f);
    int pv; pv = 100;
    printf("pv = %d\n", pv);
    float pf; pf = 2.718f;
    printf("pf = %f\n", pf);
    check_int(1, 1, 801);   // 走到這裡代表 printf 沒 crash

    // ════════════════════════════════════════════════
    // 9. ## 運算子
    //    a ## b = a^b + b^a
    // ════════════════════════════════════════════════
    printf("=== 9. ## operator ===\n");
    float ha; ha = 2.0f;
    float hb; hb = 3.0f;
    float hr;

    // 2.0 ## 3.0 = 2^3 + 3^2 = 8 + 9 = 17
    hr = ha ## hb;
    check_float(17.0f, hr, 901);

    // 1.0 ## 1.0 = 1^1 + 1^1 = 2
    ha = 1.0f; hb = 1.0f;
    hr = ha ## hb;
    check_float(2.0f, hr, 902);

    // 2.0 ## 2.0 = 2^2 + 2^2 = 4 + 4 = 8
    ha = 2.0f; hb = 2.0f;
    hr = ha ## hb;
    check_float(8.0f, hr, 903);

    // ## 優先權與 * / 相同（高於 + -）
    // pa + pb ## pc = pa + (pb ## pc)
    // 2 + (3 ## 4) = 2 + (3^4+4^3) = 2 + (81+64) = 147
    float pa; pa = 2.0f;
    float pb; pb = 3.0f;
    float pc; pc = 4.0f;
    float pr;
    pr = pa + pb ## pc;
    check_float(147.0f, pr, 904);

    // (pa ## pb) + pc = 17 + 4 = 21
    pr = pa ## pb + pc;
    check_float(21.0f, pr, 905);

    // (pa ## pb) * pc = 17 * 4 = 68
    pr = pa ## pb * pc;
    check_float(68.0f, pr, 906);

    // pa * pb ## pc = (pa * pb) ## pc = 6.0 ## 4.0
    // = 6^4 + 4^6 = 1296 + 4096 = 5392
    pr = pa * pb ## pc;
    check_float(5392.0f, pr, 907);

    // ## 只能用 float
    float hf1; hf1 = 4.0f;
    float hf2; hf2 = 0.5f;
    // 4^0.5 + 0.5^4 = 2 + 0.0625 = 2.0625
    hr = hf1 ## hf2;
    check_float(2.0625f, hr, 908);

    // ════════════════════════════════════════════════
    // 10. 隱式型別轉換（加分，但文件明確列出）
    // ════════════════════════════════════════════════
    printf("=== 10. implicit type conversion ===\n");
    // float → int（截斷）
    float pi_f; pi_f = 3.99f;
    int ti;     ti = pi_f;
    check_int(3, ti, 1001);

    pi_f = -2.9f; ti = pi_f;
    check_int(-2, ti, 1002);

    pi_f = 0.9f; ti = pi_f;
    check_int(0, ti, 1003);

    // int → float
    int ia; ia = 7;
    float iaf; iaf = ia;
    check_float(7.0f, iaf, 1004);

    ia = 0; iaf = ia;
    check_float(0.0f, iaf, 1005);

    ia = -5; iaf = ia;
    check_float(-5.0f, iaf, 1006);

    // int op float → float
    float mx;
    mx = 7 + 1.5f;
    check_float(8.5f, mx, 1007);

    mx = 3 * 2.5f;
    check_float(7.5f, mx, 1008);

    int mn;
    mn = 10 + 2.9f;   // 截斷
    check_int(12, mn, 1009);

    // ════════════════════════════════════════════════
    // 總結
    // ════════════════════════════════════════════════
    printf("\n========================================\n");
    printf("TOTAL PASS: %d\n", total_pass);
    printf("TOTAL FAIL: %d\n", total_fail);
    if (total_fail == 0) {
        printf("ALL PASS - 80 分基本要求完全通過\n");
    } else {
        printf("SOME FAILED - 請檢查上方 FAIL 項目\n");
    }
    printf("========================================\n");

    return 0;
}
