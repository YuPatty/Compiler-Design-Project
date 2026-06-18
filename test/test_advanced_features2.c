// test_advanced_features.c
// 驗證：
//   1. qsort / bsearch
//   2. localtime / gmtime / mktime / strftime / difftime
//   3. lround / llround / nearbyint

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

// ═══════════════════════════════════════════════════════════════
// ① qsort / bsearch
// ═══════════════════════════════════════════════════════════════

// ── 整數升冪比較函式（qsort / bsearch 共用）──
int cmp_int(int *a, int *b) {
    return *a - *b;
}

// ── 字串字典序比較函式（char* 陣列排序用）──
int cmp_str(char **a, char **b) {
    return strcmp(*a, *b);
}

// ── double 升冪比較函式 ──
int cmp_double(double *a, double *b) {
    if (*a < *b) return -1;
    if (*a > *b) return  1;
    return 0;
}

void test_qsort_bsearch() {
    printf("=== qsort / bsearch ===\n");

    // ──────────────────────────────
    // (A) 整數陣列排序 + bsearch 搜尋
    // ──────────────────────────────
    int nums[8];
    nums[0] = 40; nums[1] = 10; nums[2] = 70;
    nums[3] = 30; nums[4] = 90; nums[5] = 20;
    nums[6] = 60; nums[7] = 50;

    qsort(nums, 8, sizeof(int), cmp_int);

    printf("sorted ints:");
    int i;
    i = 0;
    while (i < 8) {
        printf(" %d", nums[i]);
        i = i + 1;
    }
    printf("\n");
    // expected: 10 20 30 40 50 60 70 90

    // bsearch 找存在的值
    int key1;
    key1 = 30;
    int *found1;
    found1 = bsearch(&key1, nums, 8, sizeof(int), cmp_int);
    if (found1 != 0) {
        printf("bsearch(30) found: %d\n", *found1);   // 30
    } else {
        printf("bsearch(30) NOT found\n");
    }

    // bsearch 找不存在的值
    int key2;
    key2 = 55;
    int *found2;
    found2 = bsearch(&key2, nums, 8, sizeof(int), cmp_int);
    if (found2 != 0) {
        printf("bsearch(55) found: %d\n", *found2);
    } else {
        printf("bsearch(55) NOT found\n");   // NOT found
    }

    // bsearch 找邊界值（最小 / 最大）
    int key3;
    key3 = 10;
    int *found3;
    found3 = bsearch(&key3, nums, 8, sizeof(int), cmp_int);
    if (found3 != 0) {
        printf("bsearch(10) found: %d\n", *found3);   // 10
    } else {
        printf("bsearch(10) NOT found\n");
    }

    int key4;
    key4 = 90;
    int *found4;
    found4 = bsearch(&key4, nums, 8, sizeof(int), cmp_int);
    if (found4 != 0) {
        printf("bsearch(90) found: %d\n", *found4);   // 90
    } else {
        printf("bsearch(90) NOT found\n");
    }

    // ──────────────────────────────
    // (B) double 陣列排序
    // ──────────────────────────────
    double dvals[5];
    dvals[0] = 3.14; dvals[1] = 1.41; dvals[2] = 2.71;
    dvals[3] = 0.57; dvals[4] = 1.73;

    qsort(dvals, 5, sizeof(double), cmp_double);

    printf("sorted doubles:");
    int j;
    j = 0;
    while (j < 5) {
        printf(" %.2f", dvals[j]);
        j = j + 1;
    }
    printf("\n");
    // expected: 0.57 1.41 1.73 2.71 3.14

    // ──────────────────────────────
    // (C) 小陣列邊界：長度為 1
    // ──────────────────────────────
    int single[1];
    single[0] = 42;
    qsort(single, 1, sizeof(int), cmp_int);
    printf("single-element qsort: %d\n", single[0]);   // 42

    // ──────────────────────────────
    // (D) 已排序陣列再次 qsort（穩定性驗證）
    // ──────────────────────────────
    int sorted[4];
    sorted[0] = 1; sorted[1] = 2; sorted[2] = 3; sorted[3] = 4;
    qsort(sorted, 4, sizeof(int), cmp_int);
    printf("re-sorted:");
    int k;
    k = 0;
    while (k < 4) {
        printf(" %d", sorted[k]);
        k = k + 1;
    }
    printf("\n");
    // expected: 1 2 3 4

    // ──────────────────────────────
    // (E) 逆序陣列排序
    // ──────────────────────────────
    int rev[5];
    rev[0] = 5; rev[1] = 4; rev[2] = 3; rev[3] = 2; rev[4] = 1;
    qsort(rev, 5, sizeof(int), cmp_int);
    printf("reverse-sorted:");
    int m;
    m = 0;
    while (m < 5) {
        printf(" %d", rev[m]);
        m = m + 1;
    }
    printf("\n");
    // expected: 1 2 3 4 5
}

// ═══════════════════════════════════════════════════════════════
// ② time.h：localtime / gmtime / mktime / strftime / difftime
// ═══════════════════════════════════════════════════════════════

void test_time_h() {
    printf("\n=== time.h ===\n");

    // ──────────────────────────────
    // (A) 固定 epoch 時間戳 → localtime → 欄位讀取
    //     使用 1700000000（2023-11-14 22:13:20 UTC）
    //     避免 time() 結果不確定
    // ──────────────────────────────
    long t1;
    t1 = 1700000000;

    struct tm *lt;
    lt = localtime(&t1);

    // 只驗證 UTC+0 以下不隨時區變動的欄位 wday / yday（會隨時區而異，跳過）
    // 改驗 mktime(localtime(t)) 應還原回相同秒數（round-trip）
    long t2;
    t2 = mktime(lt);
    if (t2 == t1) {
        printf("mktime(localtime(t1)) == t1 : OK\n");
    } else {
        // 接受誤差（DST 等因素）
        long diff;
        diff = t2 - t1;
        if (diff < 0) diff = -diff;
        if (diff <= 3600) {
            printf("mktime(localtime(t1)) round-trip within 1h: OK\n");
        } else {
            printf("mktime round-trip diff = %ld  (unexpected)\n", diff);
        }
    }

    // ──────────────────────────────
    // (B) gmtime → 讀取 UTC 欄位（確定值）
    // ──────────────────────────────
    long tg;
    tg = 0;   // Unix epoch: 1970-01-01 00:00:00 UTC
    struct tm *gm;
    gm = gmtime(&tg);

    printf("epoch gmtime: year=%d mon=%d mday=%d hour=%d min=%d sec=%d\n",
           gm->tm_year + 1900,   // 1970
           gm->tm_mon  + 1,      // 1
           gm->tm_mday,          // 1
           gm->tm_hour,          // 0
           gm->tm_min,           // 0
           gm->tm_sec);          // 0
    // expected: year=1970 mon=1 mday=1 hour=0 min=0 sec=0

    long tg2;
    tg2 = 86400;   // exactly 1 day after epoch
    struct tm *gm2;
    gm2 = gmtime(&tg2);
    printf("epoch+1day: year=%d mon=%d mday=%d\n",
           gm2->tm_year + 1900,  // 1970
           gm2->tm_mon  + 1,     // 1
           gm2->tm_mday);        // 2

    // ──────────────────────────────
    // (C) mktime：用已知 UTC struct tm 構造 epoch
    //     注意 mktime 使用本地時間，所以直接驗證往返
    // ──────────────────────────────
    struct tm my_tm;
    my_tm.tm_year  = 2024 - 1900;
    my_tm.tm_mon   = 6 - 1;     // June
    my_tm.tm_mday  = 15;
    my_tm.tm_hour  = 12;
    my_tm.tm_min   = 0;
    my_tm.tm_sec   = 0;
    my_tm.tm_isdst = -1;        // let mktime decide

    long t3;
    t3 = mktime(&my_tm);
    if (t3 > 0) {
        printf("mktime(2024-06-15 12:00:00 local) > 0 : OK  (t=%ld)\n", t3);
    } else {
        printf("mktime returned unexpected value: %ld\n", t3);
    }

    // localtime round-trip：mktime → localtime → mktime
    struct tm *lt2;
    lt2 = localtime(&t3);
    long t4;
    t4 = mktime(lt2);
    if (t4 == t3) {
        printf("mktime round-trip: OK\n");
    } else {
        printf("mktime round-trip mismatch: %ld vs %ld\n", t3, t4);
    }

    // ──────────────────────────────
    // (D) strftime：格式化輸出
    // ──────────────────────────────
    char buf[64];
    long te;
    te = 0;   // epoch
    struct tm *gme;
    gme = gmtime(&te);

    int n;
    n = strftime(buf, 64, "%Y-%m-%d %H:%M:%S", gme);
    printf("strftime epoch UTC : %s  (n=%d)\n", buf, n);
    // expected: 1970-01-01 00:00:00  (n=19)

    // 另一個格式
    int n2;
    n2 = strftime(buf, 64, "%A", gme);   // weekday name
    printf("strftime weekday   : %s\n", buf);
    // epoch 是 Thursday（星期四）

    // 緩衝區截斷：maxsize=5（太小），應回傳 0
    int n3;
    n3 = strftime(buf, 5, "%Y-%m-%d", gme);
    if (n3 == 0) {
        printf("strftime truncated (n=0): OK\n");
    } else {
        printf("strftime truncated n=%d (unexpected)\n", n3);
    }

    // ──────────────────────────────
    // (E) difftime
    // ──────────────────────────────
    long ta;
    long tb;
    ta = 1000;
    tb = 1500;

    double d1;
    d1 = difftime(tb, ta);
    printf("difftime(1500, 1000) = %.1f\n", d1);   // 500.0

    double d2;
    d2 = difftime(ta, tb);
    printf("difftime(1000, 1500) = %.1f\n", d2);   // -500.0

    double d3;
    d3 = difftime(ta, ta);
    printf("difftime(t, t)       = %.1f\n", d3);   // 0.0
}

// ═══════════════════════════════════════════════════════════════
// ③ lround / llround / nearbyint
// ═══════════════════════════════════════════════════════════════

void test_rounding() {
    printf("\n=== lround / llround / nearbyint ===\n");

    // ──────────────────────────────
    // (A) lround：四捨五入到 long（遠離零方向）
    // ──────────────────────────────
    printf("--- lround ---\n");
    printf("lround(2.3)  = %ld\n",  lround(2.3));    //  2
    printf("lround(2.5)  = %ld\n",  lround(2.5));    //  3
    printf("lround(2.7)  = %ld\n",  lround(2.7));    //  3
    printf("lround(-2.3) = %ld\n",  lround(-2.3));   // -2
    printf("lround(-2.5) = %ld\n",  lround(-2.5));   // -3
    printf("lround(-2.7) = %ld\n",  lround(-2.7));   // -3
    printf("lround(0.0)  = %ld\n",  lround(0.0));    //  0
    printf("lround(0.5)  = %ld\n",  lround(0.5));    //  1
    printf("lround(-0.5) = %ld\n",  lround(-0.5));   // -1
    printf("lround(100.9)= %ld\n",  lround(100.9));  // 101

    // ──────────────────────────────
    // (B) llround：和 lround 相同語意，但明確是 long long (i64)
    // ──────────────────────────────
    printf("--- llround ---\n");
    printf("llround(2.3)  = %ld\n",  llround(2.3));    //  2
    printf("llround(2.5)  = %ld\n",  llround(2.5));    //  3
    printf("llround(-2.5) = %ld\n",  llround(-2.5));   // -3
    printf("llround(1e9)  = %ld\n",  llround(1e9));    // 1000000000
    // 大數值（超 i32 範圍，驗證確實是 i64）
    printf("llround(3e15) = %ld\n",  llround(3e15));   // 3000000000000000

    // ──────────────────────────────
    // (C) nearbyint：依當前捨入模式（預設：銀行家捨入 / round-to-even）
    //     預設 FE_TONEAREST = round half to even
    // ──────────────────────────────
    printf("--- nearbyint ---\n");
    printf("nearbyint(2.0)  = %.1f\n", nearbyint(2.0));    // 2.0
    printf("nearbyint(2.3)  = %.1f\n", nearbyint(2.3));    // 2.0
    printf("nearbyint(2.7)  = %.1f\n", nearbyint(2.7));    // 3.0
    printf("nearbyint(2.5)  = %.1f\n", nearbyint(2.5));    // 2.0（round-to-even：就近偶數）
    printf("nearbyint(3.5)  = %.1f\n", nearbyint(3.5));    // 4.0（round-to-even）
    printf("nearbyint(-2.5) = %.1f\n", nearbyint(-2.5));   // -2.0
    printf("nearbyint(-3.5) = %.1f\n", nearbyint(-3.5));   // -4.0
    printf("nearbyint(0.0)  = %.1f\n", nearbyint(0.0));    // 0.0
    printf("nearbyint(-0.0) = %.1f\n", nearbyint(-0.0));   // -0.0

    // ──────────────────────────────
    // (D) lround vs nearbyint 差異對比（0.5 處）
    // ──────────────────────────────
    printf("--- 0.5 comparison ---\n");
    printf("lround(0.5)      = %ld\n",  lround(0.5));       //  1（遠離零）
    printf("nearbyint(0.5)   = %.1f\n", nearbyint(0.5));    //  0.0（even）
    printf("lround(1.5)      = %ld\n",  lround(1.5));       //  2（遠離零）
    printf("nearbyint(1.5)   = %.1f\n", nearbyint(1.5));    //  2.0（even，相同）
    printf("lround(-0.5)     = %ld\n",  lround(-0.5));      // -1（遠離零）
    printf("nearbyint(-0.5)  = %.1f\n", nearbyint(-0.5));   // -0.0（even）

    // ──────────────────────────────
    // (E) 與 round() 對比：round 也是遠離零，但回傳 double
    // ──────────────────────────────
    printf("--- round vs lround ---\n");
    printf("round(2.5)  = %.1f   lround(2.5)  = %ld\n", round(2.5),  lround(2.5));   // 3.0  3
    printf("round(-2.5) = %.1f  lround(-2.5) = %ld\n", round(-2.5), lround(-2.5));   // -3.0 -3

    // ──────────────────────────────
    // (F) 整數輸入也能用（型別自動提升）
    // ──────────────────────────────
    printf("--- integer input ---\n");
    int iv;
    iv = 7;
    printf("lround(int 7)     = %ld\n",  lround(iv));       // 7
    printf("llround(int 7)    = %ld\n",  llround(iv));      // 7
    printf("nearbyint(int 7)  = %.1f\n", nearbyint(iv));    // 7.0

    double dv;
    dv = -9.99;
    printf("lround(-9.99)     = %ld\n",  lround(dv));       // -10
    printf("llround(-9.99)    = %ld\n",  llround(dv));      // -10
    printf("nearbyint(-9.99)  = %.1f\n", nearbyint(dv));    // -10.0
}

// ═══════════════════════════════════════════════════════════════
// main
// ═══════════════════════════════════════════════════════════════

int main(void) {
    test_qsort_bsearch();
    test_time_h();
    test_rounding();
    return 0;
}
