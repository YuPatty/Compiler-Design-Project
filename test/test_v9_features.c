// ── 測試 4：新功能整合測試 ──
// 涵蓋：Loop Unrolling / setjmp-longjmp / Flexible Array Member /
//        stdio 補完（puts/gets/freopen/fflush）/
//        stdlib 補完（aligned_alloc / _Exit）/
//        字串補完（strsep / asprintf）

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>

// ══════════════════════════════════════════════════════════════════
// 測試 A：Loop Unrolling
//   for (int i = 0; i < 4; i++) 這種小迴圈應被完全展開，
//   IR 中不會出現 Lfor_cond / Lfor_body label。
// ══════════════════════════════════════════════════════════════════
void test_loop_unroll() {
    printf("=== Loop Unrolling ===\n");

    // A1：簡單累加（4 次，展開後無迴圈 IR）
    int sum = 0;
    for (int i = 0; i < 4; i++) {
        sum += i;          // 0+1+2+3 = 6
    }
    printf("sum(0..3) = %d\n", sum);          // 期望：6

    // A2：累乘（5 次）
    int prod = 1;
    for (int i = 1; i <= 5; i++) {
        prod *= i;         // 5! = 120
    }
    printf("5! = %d\n", prod);                // 期望：120

    // A3：步長為 2（i = 0, 2, 4, 6, 8）
    int s2 = 0;
    for (int i = 0; i < 10; i += 2) {
        s2 += i;           // 0+2+4+6+8 = 20
    }
    printf("even sum = %d\n", s2);            // 期望：20

    // A4：超過展開門檻（> 128 次）→ 不展開，照常執行
    int big = 0;
    for (int i = 0; i < 200; i++) {
        big += 1;
    }
    printf("big loop = %d\n", big);           // 期望：200

    // A5：i != 結束條件
    int ne_sum = 0;
    for (int i = 0; i != 5; i++) {
        ne_sum += i;       // 0+1+2+3+4 = 10
    }
    printf("ne sum = %d\n", ne_sum);          // 期望：10
}

// ══════════════════════════════════════════════════════════════════
// 測試 B：Flexible Array Member（C99 FAM）
//   struct Packet { int len; char data[]; };
//   用 malloc(sizeof(struct) + N) 動態配置，data 像陣列一樣存取。
// ══════════════════════════════════════════════════════════════════
struct Packet {
    int len;
    char data[];
};

struct IntArray {
    int count;
    int vals[];
};

void test_fam() {
    printf("=== Flexible Array Member ===\n");

    // B1：字元陣列
    int n = 5;
    struct Packet *pkt = (struct Packet *)malloc(sizeof(struct Packet) + n);
    pkt->len = n;
    pkt->data[0] = 'H';
    pkt->data[1] = 'e';
    pkt->data[2] = 'l';
    pkt->data[3] = 'l';
    pkt->data[4] = 'o';
    printf("pkt->len = %d\n", pkt->len);     // 期望：5
    printf("pkt->data = ");
    for (int i = 0; i < pkt->len; i++) {
        printf("%c", pkt->data[i]);           // 期望：Hello
    }
    printf("\n");
    free(pkt);

    // B2：整數陣列
    int m = 4;
    struct IntArray *ia = (struct IntArray *)malloc(sizeof(struct IntArray) + m * sizeof(int));
    ia->count = m;
    ia->vals[0] = 10; ia->vals[1] = 20; ia->vals[2] = 30; ia->vals[3] = 40;
    int total = 0;
    for (int i = 0; i < ia->count; i++) total += ia->vals[i];
    printf("ia total = %d\n", total);         // 期望：100
    free(ia);
}

// ══════════════════════════════════════════════════════════════════
// 測試 C：setjmp / longjmp
//   C1：基本跳轉（模擬例外處理）
//   C2：巢狀函式中的 longjmp
// ══════════════════════════════════════════════════════════════════
jmp_buf g_env;

void may_fail(int x) {
    if (x < 0) {
        longjmp(g_env, 1);   // 跳回 setjmp，讓它回傳 1
    }
    printf("may_fail(%d) ok\n", x);           // 期望：只有 x >= 0 才印
}

void test_setjmp() {
    printf("=== setjmp / longjmp ===\n");

    // C1：正常路徑
    int r1 = setjmp(g_env);
    if (r1 == 0) {
        may_fail(5);                           // 期望印出：may_fail(5) ok
        printf("after may_fail(5)\n");         // 期望印出
    }

    // C2：觸發 longjmp
    int r2 = setjmp(g_env);
    if (r2 == 0) {
        may_fail(-1);                          // 觸發 longjmp
        printf("SHOULD NOT PRINT\n");          // 不應印出
    } else {
        printf("caught longjmp, r2=%d\n", r2);// 期望：caught longjmp, r2=1
    }
}

// ══════════════════════════════════════════════════════════════════
// 測試 D：stdio 補完
//   puts / fflush
//   （gets 不測，不安全且行為依賴 stdin）
//   （freopen 不測，會改變 stdout 方向）
// ══════════════════════════════════════════════════════════════════
void test_stdio() {
    printf("=== stdio ===\n");

    // D1：puts（自動換行）
    puts("puts: hello world");                 // 期望：puts: hello world\n

    // D2：fflush（排空緩衝區，回傳 0 表示成功）
    printf("before fflush");
    int ff = fflush(stdout);
    printf("\n");
    printf("fflush(stdout) = %d\n", ff);       // 期望：fflush(stdout) = 0
}

// ══════════════════════════════════════════════════════════════════
// 測試 E：stdlib 補完
//   aligned_alloc / _Exit
// ══════════════════════════════════════════════════════════════════
void test_stdlib() {
    printf("=== stdlib ===\n");

    // E1：aligned_alloc（16 位元組對齊，配置 64 bytes）
    int *buf = (int *)aligned_alloc(16, 64);
    buf[0] = 42; buf[1] = 100;
    printf("aligned buf[0]=%d buf[1]=%d\n", buf[0], buf[1]); // 期望：42 100
    // 驗證對齊（位址 % 16 == 0）
    long addr = (long)buf;
    printf("aligned=%d\n", (addr % 16 == 0) ? 1 : 0);        // 期望：1
    free(buf);

    // E2：_Exit 的存在性（不實際呼叫，否則程式終止）
    printf("_Exit defined (not called)\n");    // 期望：印出
}

// ══════════════════════════════════════════════════════════════════
// 測試 F：字串補完
//   strsep / asprintf
// ══════════════════════════════════════════════════════════════════
void test_string() {
    printf("=== string ===\n");

    // F1：strsep（依 "," 切割）
    char src[] = "apple,banana,,cherry";
    char *p = src;
    int idx = 0;
    char *tok;
    while ((tok = strsep(&p, ",")) != NULL) {
        // strsep 支援空欄位（不像 strtok 跳過）
        printf("tok[%d]=\"%s\"\n", idx++, tok);
    }
    // 期望：
    //   tok[0]="apple"
    //   tok[1]="banana"
    //   tok[2]=""         ← 空欄位，strtok 會跳過但 strsep 不會
    //   tok[3]="cherry"

    // F2：asprintf（自動配置記憶體的 sprintf）
    char *out = NULL;
    int len = asprintf(&out, "pi=%.2f n=%d", 3.14, 42);
    printf("asprintf len=%d str=%s\n", len, out); // 期望：len=12 str=pi=3.14 n=42
    free(out);
}

// ══════════════════════════════════════════════════════════════════
// main
// ══════════════════════════════════════════════════════════════════
int main() {
    test_loop_unroll();
    printf("\n");
    test_fam();
    printf("\n");
    test_setjmp();
    printf("\n");
    test_stdio();
    printf("\n");
    test_stdlib();
    printf("\n");
    test_string();
    return 0;
}
