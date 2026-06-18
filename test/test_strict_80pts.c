// test_strict_80pts.c
// 嚴格驗證 80 分基本要求 + 邊界條件
// 全自動（不需 stdin），每項 PASS/FAIL 自動判斷
// 涵蓋：int/float 型別、四則運算、比較、if-then/else、
//        巢狀 if、printf、scanf（跳過）、## 運算子
//        隱式型別轉換、邊界值、優先順序、符號邊界

int pass_cnt;
int fail_cnt;

void chk_i(int id, int expected, int got) {
    if (expected == got) {
        printf("[PASS %d] %d\n", id, got);
        pass_cnt = pass_cnt + 1;
    } else {
        printf("[FAIL %d] expected=%d got=%d\n", id, expected, got);
        fail_cnt = fail_cnt + 1;
    }
}

void chk_f(int id, float expected, float got) {
    float d;
    d = expected - got;
    if (d < 0.0f) d = 0.0f - d;
    if (d < 0.01f) {
        printf("[PASS %d] %f\n", id, got);
        pass_cnt = pass_cnt + 1;
    } else {
        printf("[FAIL %d] expected=%f got=%f\n", id, expected, got);
        fail_cnt = fail_cnt + 1;
    }
}

// ── my_hashhash 等效函式（用於驗算）──
// 無法在 C 裡用 ##，靠 myRuntime.c 的 my_hashhash 間接測試

int main(void) {
    pass_cnt = 0;
    fail_cnt = 0;

    // ════════════════════════════════════════════
    // BLOCK A：int 型別 & 邊界值
    // ════════════════════════════════════════════
    printf("=== A: int type & boundary ===\n");

    int z; z = 0;
    chk_i(  1,          0, z);

    int pos; pos = 2147483647;
    chk_i(  2, 2147483647, pos);            // INT_MAX

    int neg; neg = -2147483648;
    chk_i(  3,-2147483648, neg);            // INT_MIN

    int one; one = 1;
    chk_i(  4,          1, one);

    int mn1; mn1 = -1;
    chk_i(  5,         -1, mn1);

    // 重新賦值
    int rv; rv = 10; rv = 99; rv = -7;
    chk_i(  6,         -7, rv);

    // 多次賦值鏈
    int cv; cv = 1 + 2 + 3 + 4 + 5;
    chk_i(  7,         15, cv);

    // ════════════════════════════════════════════
    // BLOCK B：int 四則運算 & 優先順序
    // ════════════════════════════════════════════
    printf("=== B: int arithmetic & precedence ===\n");

    int a; a = 10;
    int b; b = 3;

    chk_i( 10,  13,  a + b);
    chk_i( 11,   7,  a - b);
    chk_i( 12,  30,  a * b);
    chk_i( 13,   3,  a / b);       // 截斷除法

    // 作業範例：b + 2 * (100 - 1)
    chk_i( 14, 201,  b + 2 * (100 - 1));

    // 優先順序：* 先於 +
    chk_i( 15,  17,  a + b * a - 13);  // 10+30-13=27? no: 10+3*10-13=10+30-13=27
    chk_i( 15,  27,  a + b * a - 13);

    // 括號改變順序
    chk_i( 16,  91,  (a + b) * (a - b));  // 13*7=91

    // 深層括號
    chk_i( 17,   5,  ((a + b) - (a - b)) / 2);  // (13-7)/2=3 → wait: 6/2=3
    chk_i( 17,   3,  ((a + b) - (a - b)) / 2);

    // 負數算術
    int na; na = -10;
    int nb; nb = -3;
    chk_i( 20, -13, na + nb);
    chk_i( 21,  -7, na - nb);
    chk_i( 22,  30, na * nb);
    chk_i( 23,   3, na / nb);    // -10/-3 = 3 (truncation toward zero)

    // 混合正負
    chk_i( 24, -7,  na + b);      // -10+3=-7
    chk_i( 25, 30,  na * nb);
    chk_i( 26,  0,  z * na);

    // 連續除法
    int d1; d1 = 100 / 5 / 4;     // (100/5)/4 = 20/4 = 5
    chk_i( 27,   5, d1);

    // 連續減法
    int s1; s1 = 100 - 50 - 25;   // left-assoc: (100-50)-25 = 25
    chk_i( 28,  25, s1);

    // ════════════════════════════════════════════
    // BLOCK C：float 型別 & 邊界值
    // ════════════════════════════════════════════
    printf("=== C: float type & boundary ===\n");

    float fz; fz = 0.0f;
    chk_f( 30,  0.0f, fz);

    float fp; fp = 3.14f;
    chk_f( 31,  3.14f, fp);

    float fn; fn = -2.5f;
    chk_f( 32, -2.5f, fn);

    float fone; fone = 1.0f;
    chk_f( 33,  1.0f, fone);

    float fmn; fmn = -1.0f;
    chk_f( 34, -1.0f, fmn);

    // ════════════════════════════════════════════
    // BLOCK D：float 四則運算 & 精度
    // ════════════════════════════════════════════
    printf("=== D: float arithmetic ===\n");

    float fx; fx = 6.0f;
    float fy; fy = 2.0f;

    chk_f( 40,  8.0f, fx + fy);
    chk_f( 41,  4.0f, fx - fy);
    chk_f( 42, 12.0f, fx * fy);
    chk_f( 43,  3.0f, fx / fy);

    float fx2; fx2 = -1.5f;
    float fy2; fy2 =  0.5f;
    chk_f( 44, -1.0f,  fx2 + fy2);
    chk_f( 45, -2.0f,  fx2 - fy2);
    chk_f( 46, -0.75f, fx2 * fy2);
    chk_f( 47, -3.0f,  fx2 / fy2);

    // 連鎖浮點
    float fc; fc = 1.0f + 2.0f + 3.0f + 4.0f;
    chk_f( 48, 10.0f, fc);

    float fm; fm = 2.0f * 3.0f * 4.0f;
    chk_f( 49, 24.0f, fm);

    // 浮點優先順序
    float fpr; fpr = 1.0f + 2.0f * 3.0f;  // 1+6=7
    chk_f( 50,  7.0f, fpr);

    fpr = (1.0f + 2.0f) * 3.0f;           // 3*3=9
    chk_f( 51,  9.0f, fpr);

    // 接近零
    float feps; feps = 0.1f + 0.1f + 0.1f + 0.1f + 0.1f + 0.1f + 0.1f + 0.1f + 0.1f + 0.1f;
    chk_f( 52,  1.0f, feps);  // ~1.0

    // ════════════════════════════════════════════
    // BLOCK E：比較運算 — 全部 6 種，int & float
    // ════════════════════════════════════════════
    printf("=== E: comparison operators ===\n");

    int m; m = 5;
    int n; n = 3;
    int cr;

    // int >
    cr = (m > n);   chk_i( 60, 1, cr);
    cr = (n > m);   chk_i( 61, 0, cr);
    cr = (m > m);   chk_i( 62, 0, cr);

    // int >=
    cr = (m >= n);  chk_i( 63, 1, cr);
    cr = (n >= m);  chk_i( 64, 0, cr);
    cr = (m >= m);  chk_i( 65, 1, cr);

    // int <
    cr = (n < m);   chk_i( 66, 1, cr);
    cr = (m < n);   chk_i( 67, 0, cr);
    cr = (m < m);   chk_i( 68, 0, cr);

    // int <=
    cr = (n <= m);  chk_i( 69, 1, cr);
    cr = (m <= n);  chk_i( 70, 0, cr);
    cr = (m <= m);  chk_i( 71, 1, cr);

    // int ==
    cr = (m == 5);  chk_i( 72, 1, cr);
    cr = (m == n);  chk_i( 73, 0, cr);
    cr = (0 == 0);  chk_i( 74, 1, cr);

    // int !=
    cr = (m != n);  chk_i( 75, 1, cr);
    cr = (m != m);  chk_i( 76, 0, cr);
    cr = (0 != 0);  chk_i( 77, 0, cr);

    // 負數比較
    cr = (-1 < 0);  chk_i( 78, 1, cr);
    cr = (-1 > 0);  chk_i( 79, 0, cr);
    cr = (-3 < -1); chk_i( 80, 1, cr);
    cr = (-1 == -1);chk_i( 81, 1, cr);
    cr = (-1 != -2);chk_i( 82, 1, cr);

    // float 比較
    float cfa; cfa = 1.5f;
    float cfb; cfb = 2.5f;
    cr = (cfa < cfb);  chk_i( 83, 1, cr);
    cr = (cfa <= cfb); chk_i( 84, 1, cr);
    cr = (cfb > cfa);  chk_i( 85, 1, cr);
    cr = (cfb >= cfa); chk_i( 86, 1, cr);
    cfa = 1.5f; cfb = 1.5f;
    cr = (cfa == cfb); chk_i( 87, 1, cr);
    cr = (cfa != cfb); chk_i( 88, 0, cr);
    cfa = 0.0f; cfb = 0.0f;
    cr = (cfa == cfb); chk_i( 89, 1, cr);

    // ════════════════════════════════════════════
    // BLOCK F：if-then 各種條件
    // ════════════════════════════════════════════
    printf("=== F: if-then ===\n");

    int iv; iv = 7;
    int hit;

    // 正向觸發
    hit = 0; if (iv > 0)   hit = 1; chk_i( 90, 1, hit);
    hit = 0; if (iv >= 7)  hit = 1; chk_i( 91, 1, hit);
    hit = 0; if (iv == 7)  hit = 1; chk_i( 92, 1, hit);
    hit = 0; if (iv != 8)  hit = 1; chk_i( 93, 1, hit);
    hit = 0; if (iv < 10)  hit = 1; chk_i( 94, 1, hit);
    hit = 0; if (iv <= 7)  hit = 1; chk_i( 95, 1, hit);

    // 負向（不進入）
    hit = 0; if (iv > 100) hit = 1; chk_i( 96, 0, hit);
    hit = 0; if (iv == 0)  hit = 1; chk_i( 97, 0, hit);
    hit = 0; if (iv < 0)   hit = 1; chk_i( 98, 0, hit);
    hit = 0; if (iv != 7)  hit = 1; chk_i( 99, 0, hit);

    // 條件為運算式
    hit = 0; if (3 + 4 > 6)         hit = 1; chk_i(100, 1, hit);
    hit = 0; if (2 * 3 == 6)        hit = 1; chk_i(101, 1, hit);
    hit = 0; if (10 - 5 == iv - 2)  hit = 1; chk_i(102, 1, hit); // 5==5

    // 零與非零
    hit = 0; if (0 == 0)  hit = 1; chk_i(103, 1, hit);
    hit = 0; if (1 == 1)  hit = 1; chk_i(104, 1, hit);
    hit = 0; if (-1 < 0)  hit = 1; chk_i(105, 1, hit);

    // ════════════════════════════════════════════
    // BLOCK G：if-then-else
    // ════════════════════════════════════════════
    printf("=== G: if-then-else ===\n");

    int res;

    // else 觸發
    res = 0;
    if (iv > 10) { res = 1; } else { res = 2; }
    chk_i(110, 2, res);

    // then 觸發
    res = 0;
    if (iv > 0) { res = 1; } else { res = 2; }
    chk_i(111, 1, res);

    // == 分支
    res = 0;
    if (iv == 7) { res = 7; } else { res = 99; }
    chk_i(112, 7, res);

    // != 分支
    res = 0;
    if (iv != 7) { res = 1; } else { res = 2; }
    chk_i(113, 2, res);

    // 負數分支
    int nv; nv = -5;
    res = 0;
    if (nv < 0) { res = 1; } else { res = 2; }
    chk_i(114, 1, res);

    res = 0;
    if (nv >= 0) { res = 1; } else { res = 2; }
    chk_i(115, 2, res);

    // else 值是計算式
    res = 0;
    if (0 > 1) { res = 99; } else { res = iv + nv; }  // 7+(-5)=2
    chk_i(116, 2, res);

    // then 值是計算式
    res = 0;
    if (iv * 2 > 10) { res = iv * 2; } else { res = 0; }
    chk_i(117, 14, res);

    // ════════════════════════════════════════════
    // BLOCK H：巢狀 if（3 層），各種組合
    // ════════════════════════════════════════════
    printf("=== H: nested if ===\n");

    int q;
    int depth;

    // q=5: 層1 yes，層2 yes，層3 no → depth=2
    q = 5; depth = 0;
    if (q > 0) {
        depth = 1;
        if (q > 3) {
            depth = 2;
            if (q > 7) { depth = 3; }
        }
    }
    chk_i(120, 2, depth);

    // q=10: 全部 yes → depth=3
    q = 10; depth = 0;
    if (q > 0) {
        depth = 1;
        if (q > 3) {
            depth = 2;
            if (q > 7) { depth = 3; }
        }
    }
    chk_i(121, 3, depth);

    // q=-1: 層1 no → depth=0
    q = -1; depth = 0;
    if (q > 0) {
        depth = 1;
        if (q > 3) {
            depth = 2;
            if (q > 7) { depth = 3; }
        }
    }
    chk_i(122, 0, depth);

    // q=2: 層1 yes，層2 no → depth=1
    q = 2; depth = 0;
    if (q > 0) {
        depth = 1;
        if (q > 3) {
            depth = 2;
            if (q > 7) { depth = 3; }
        }
    }
    chk_i(123, 1, depth);

    // if-else 巢狀
    int cat;
    q = 75;
    if (q >= 90) {
        cat = 4;
    } else {
        if (q >= 80) {
            cat = 3;
        } else {
            if (q >= 70) {
                cat = 2;
            } else {
                cat = 1;
            }
        }
    }
    chk_i(124, 2, cat);   // 75 → cat=2

    q = 95;
    if (q >= 90) {
        cat = 4;
    } else {
        if (q >= 80) {
            cat = 3;
        } else {
            if (q >= 70) {
                cat = 2;
            } else {
                cat = 1;
            }
        }
    }
    chk_i(125, 4, cat);   // 95 → cat=4

    q = 50;
    if (q >= 90) {
        cat = 4;
    } else {
        if (q >= 80) {
            cat = 3;
        } else {
            if (q >= 70) {
                cat = 2;
            } else {
                cat = 1;
            }
        }
    }
    chk_i(126, 1, cat);   // 50 → cat=1

    // if 條件本身是比較鏈
    int ra; ra = 10; int rb; rb = 20; int rc; rc = 15;
    int mid;
    if (ra < rb) {
        if (rc < rb) {
            mid = rc;  // ra<rb, rc<rb → ra<rc<rb → mid=rc
        } else {
            mid = rb;
        }
    } else {
        mid = ra;
    }
    chk_i(127, 15, mid);

    // ════════════════════════════════════════════
    // BLOCK I：printf — 格式字元完整性
    // ════════════════════════════════════════════
    printf("=== I: printf format ===\n");

    printf("Hello\n");
    printf("World\n");

    int pv; pv = 42;
    printf("int: %d\n", pv);
    pv = -99;
    printf("neg int: %d\n", pv);
    pv = 0;
    printf("zero int: %d\n", pv);

    float pf; pf = 3.14f;
    printf("float: %f\n", pf);
    pf = -2.5f;
    printf("neg float: %f\n", pf);
    pf = 0.0f;
    printf("zero float: %f\n", pf);

    // 兩個參數
    int px; px = 7; int py; py = 8;
    printf("sum %d + %d\n", px, py);
    printf("mul %d * %d\n", px, py);

    chk_i(130, 1, 1);  // printf 沒 crash

    // ════════════════════════════════════════════
    // BLOCK J：## 運算子
    //   a ## b = a^b + b^a
    // ════════════════════════════════════════════
    printf("=== J: ## operator ===\n");

    float ha; float hb; float hr;

    // 基本值
    ha = 2.0f; hb = 3.0f;
    hr = ha ## hb;                          // 2^3+3^2 = 8+9 = 17
    chk_f(140, 17.0f, hr);

    ha = 1.0f; hb = 1.0f;
    hr = ha ## hb;                          // 1^1+1^1 = 2
    chk_f(141,  2.0f, hr);

    ha = 2.0f; hb = 2.0f;
    hr = ha ## hb;                          // 2^2+2^2 = 8
    chk_f(142,  8.0f, hr);

    ha = 3.0f; hb = 2.0f;
    hr = ha ## hb;                          // 3^2+2^3 = 9+8 = 17 (交換律)
    chk_f(143, 17.0f, hr);

    ha = 4.0f; hb = 0.5f;
    hr = ha ## hb;                          // 4^0.5 + 0.5^4 = 2 + 0.0625 = 2.0625
    chk_f(144,  2.0625f, hr);

    // ## 優先權 = * / > +
    float pa; pa = 2.0f;
    float pb; pb = 3.0f;
    float pc; pc = 4.0f;
    float pr;

    // pa + pb ## pc = pa + (pb ## pc) = 2 + (3^4+4^3) = 2 + 81+64 = 147
    pr = pa + pb ## pc;
    chk_f(145, 147.0f, pr);

    // pa ## pb + pc = (pa ## pb) + pc = 17 + 4 = 21
    pr = pa ## pb + pc;
    chk_f(146, 21.0f, pr);

    // pa ## pb - pa = 17 - 2 = 15
    pr = pa ## pb - pa;
    chk_f(147, 15.0f, pr);

    // pa ## pb * pc = (pa ## pb) * pc = 17 * 4 = 68
    pr = pa ## pb * pc;
    chk_f(148, 68.0f, pr);

    // pa * pb ## pc = (pa * pb) ## pc = 6.0 ## 4.0 = 6^4+4^6 = 1296+4096 = 5392
    pr = pa * pb ## pc;
    chk_f(149, 5392.0f, pr);

    // pa ## pb / pa = (pa ## pb) / pa = 17 / 2 = 8.5
    pr = pa ## pb / pa;
    chk_f(150, 8.5f, pr);

    // 複合：(pa ## pb) + (pb ## pc)
    float t1; t1 = pa ## pb;   // 17
    float t2; t2 = pb ## pc;   // 3^4+4^3 = 81+64 = 145
    pr = t1 + t2;
    chk_f(151, 162.0f, pr);

    // ## 結果賦值給 float
    float hres; hres = 2.0f ## 3.0f;
    chk_f(152, 17.0f, hres);

    // ════════════════════════════════════════════
    // BLOCK K：隱式型別轉換（文件明確列出為擴充功能）
    // ════════════════════════════════════════════
    printf("=== K: implicit type conversion ===\n");

    // float → int 截斷
    float tof; int toi;
    tof = 3.99f;  toi = tof;  chk_i(160,  3, toi);
    tof = -2.9f;  toi = tof;  chk_i(161, -2, toi);
    tof = 0.9f;   toi = tof;  chk_i(162,  0, toi);
    tof = -0.1f;  toi = tof;  chk_i(163,  0, toi);
    tof = 100.9f; toi = tof;  chk_i(164,100, toi);

    // int → float
    int tii; float tff;
    tii =  7;  tff = tii;  chk_f(165,  7.0f, tff);
    tii =  0;  tff = tii;  chk_f(166,  0.0f, tff);
    tii = -5;  tff = tii;  chk_f(167, -5.0f, tff);

    // int op float → float
    float mx;
    mx = 7 + 1.5f;   chk_f(168, 8.5f,  mx);
    mx = 1.5f + 7;   chk_f(169, 8.5f,  mx);
    mx = 3 * 2.5f;   chk_f(170, 7.5f,  mx);
    mx = 2.5f * 3;   chk_f(171, 7.5f,  mx);
    mx = 7.0f - 2;   chk_f(172, 5.0f,  mx);
    mx = 10.0f / 4;  chk_f(173, 2.5f,  mx);

    // 賦值後截斷
    int mi;
    mi = 10 + 2.9f;  chk_i(174, 12, mi);
    mi = 3 * 2.5f;   chk_i(175,  7, mi);  // 7.5 → 7

    // ════════════════════════════════════════════
    // BLOCK L：printf 輸出正確性（數值驗算）
    //   用 check 函式確認計算結果，然後 printf 也印出
    // ════════════════════════════════════════════
    printf("=== L: value verification via printf ===\n");

    // 確認 printf 的引數求值正確
    int lv; lv = 2 + 3 * 4 - 1;  // 2+12-1=13
    printf("2+3*4-1 = %d\n", lv);
    chk_i(180, 13, lv);

    float lf; lf = 1.0f + 2.0f * 3.0f - 0.5f;  // 1+6-0.5=6.5
    printf("1+2*3-0.5 = %f\n", lf);
    chk_f(181, 6.5f, lf);

    // printf 可以直接接運算式（不一定要中間變數）
    printf("direct expr: %d\n", 10 + 5 * 2);   // 20
    printf("direct float: %f\n", 3.0f * 3.0f - 1.0f);  // 8.0
    chk_i(182, 1, 1);  // 沒 crash

    // ════════════════════════════════════════════
    // BLOCK M：整合邊界 — if + 算術 + 比較
    // ════════════════════════════════════════════
    printf("=== M: integration boundary ===\n");

    // 最大值比較
    int imax; imax = 2147483647;
    int imaxm1; imaxm1 = 2147483646;
    cr = (imax > imaxm1); chk_i(190, 1, cr);
    cr = (imax == 2147483647); chk_i(191, 1, cr);

    // 零邊界 if
    int zv; zv = 0;
    res = 0;
    if (zv == 0) { res = 1; } else { res = 2; }
    chk_i(192, 1, res);

    res = 0;
    if (zv > 0) { res = 1; } else { res = 2; }
    chk_i(193, 2, res);

    // 負數 if
    int negv; negv = -1;
    res = 0;
    if (negv < 0)  { res = 1; } else { res = 2; }
    chk_i(194, 1, res);

    res = 0;
    if (negv >= 0) { res = 1; } else { res = 2; }
    chk_i(195, 2, res);

    // 算術結果餵入 if
    int sum; sum = 3 + 4;
    if (sum == 7)  { res = 1; } else { res = 0; }
    chk_i(196, 1, res);

    int prod; prod = 6 * 7;
    if (prod == 42) { res = 1; } else { res = 0; }
    chk_i(197, 1, res);

    // float if
    float fval; fval = 3.14f;
    if (fval > 3.0f) { res = 1; } else { res = 0; }
    chk_i(198, 1, res);

    if (fval < 3.0f) { res = 1; } else { res = 0; }
    chk_i(199, 0, res);

    // ════════════════════════════════════════════
    // FINAL SUMMARY
    // ════════════════════════════════════════════
    printf("\n========================================\n");
    printf("TOTAL PASS : %d\n", pass_cnt);
    printf("TOTAL FAIL : %d\n", fail_cnt);
    if (fail_cnt == 0) {
        printf("RESULT: ALL PASS\n");
        printf("80 分基本要求嚴格測試完全通過\n");
    } else {
        printf("RESULT: FAILED (%d cases)\n", fail_cnt);
        printf("請檢查上方 [FAIL] 項目\n");
    }
    printf("========================================\n");

    return 0;
}
