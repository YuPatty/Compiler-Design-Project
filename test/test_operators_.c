// ======================================================
// test_operators.c
// 四、運算子：% ++ -- += -= *= /= ?: && || ! & | ^ ~ << >>
// ======================================================

int main() {

    // ════════════════════════════════
    // 1. % 模除
    // ════════════════════════════════
    printf("=== modulo ===\n");
    printf("%d\n",  10 %  3);    //  1
    printf("%d\n", -10 %  3);    // -1
    printf("%d\n",  10 % -3);    //  1
    printf("%d\n",  9  %  3);    //  0
    int x; x = 17;
    x %= 5;
    printf("%d\n", x);           //  2

    // ════════════════════════════════
    // 2. ++ 前置 / 後置
    // ════════════════════════════════
    printf("=== ++ ===\n");
    int a; a = 5;
    printf("%d\n", a++);   // 5  (postfix: 先用後加)
    printf("%d\n", a);     // 6
    printf("%d\n", ++a);   // 7  (prefix:  先加後用)
    printf("%d\n", a);     // 7

    // ════════════════════════════════
    // 3. -- 前置 / 後置
    // ════════════════════════════════
    printf("=== -- ===\n");
    int b; b = 10;
    printf("%d\n", b--);   // 10 (postfix: 先用後減)
    printf("%d\n", b);     // 9
    printf("%d\n", --b);   // 8  (prefix:  先減後用)
    printf("%d\n", b);     // 8

    // ════════════════════════════════
    // 4. += -= *= /= %=
    // ════════════════════════════════
    printf("=== compound assign ===\n");
    int c; c = 10;
    c += 5;   printf("%d\n", c);   // 15
    c -= 3;   printf("%d\n", c);   // 12
    c *= 2;   printf("%d\n", c);   // 24
    c /= 4;   printf("%d\n", c);   // 6
    c %= 4;   printf("%d\n", c);   // 2
    // float 版本
    float f; f = 10.0;
    f += 2.5; printf("%f\n", f);   // 12.500000
    f -= 0.5; printf("%f\n", f);   // 12.000000
    f *= 2.0; printf("%f\n", f);   // 24.000000
    f /= 3.0; printf("%f\n", f);   // 8.000000

    // ════════════════════════════════
    // 5. 三元運算子 ? :
    // ════════════════════════════════
    printf("=== ternary ===\n");
    int v; v = 7;
    int r;
    r = (v > 5)  ? 1 : 0;    printf("%d\n", r);   // 1
    r = (v > 10) ? 1 : 0;    printf("%d\n", r);   // 0
    r = (v == 7) ? 99 : -1;  printf("%d\n", r);   // 99
    // float 結果
    float tf;
    tf = (v > 5) ? 1.5 : 2.5; printf("%f\n", tf); // 1.500000
    tf = (v < 0) ? 1.5 : 2.5; printf("%f\n", tf); // 2.500000
    // 巢狀三元
    int n; n = 0;
    r = (n > 0) ? 1 : (n < 0) ? -1 : 0;
    printf("%d\n", r);   // 0

    // ════════════════════════════════
    // 6. && || !
    // ════════════════════════════════
    printf("=== logical ===\n");
    int p; p = 1; int q; q = 0;
    if (p && q)  { printf("1\n"); } else { printf("0\n"); }  // 0
    if (p || q)  { printf("1\n"); } else { printf("0\n"); }  // 1
    if (!p)      { printf("1\n"); } else { printf("0\n"); }  // 0
    if (!q)      { printf("1\n"); } else { printf("0\n"); }  // 1
    if (p && p)  { printf("1\n"); } else { printf("0\n"); }  // 1
    if (q || q)  { printf("1\n"); } else { printf("0\n"); }  // 0
    // 與比較結合
    int m; m = 5; int k; k = 3;
    if (m > 3 && k < 5)  { printf("yes\n"); }  // yes
    if (m > 9 || k < 5)  { printf("yes\n"); }  // yes
    if (!(m == k))        { printf("ne\n");  }  // ne
    // float 型別 coerce
    float fz; fz = 0.0; float fn; fn = 1.5;
    if (!fz) { printf("fz_false\n"); }   // fz_false
    if (fn)  { printf("fn_true\n");  }   // fn_true

    // ════════════════════════════════
    // 7. & | ^ ~ << >>
    // ════════════════════════════════
    printf("=== bitwise ===\n");
    int b1; b1 = 12;   // 0000 1100
    int b2; b2 = 10;   // 0000 1010
    printf("%d\n", b1 & b2);   //  8  (0000 1000)
    printf("%d\n", b1 | b2);   // 14  (0000 1110)
    printf("%d\n", b1 ^ b2);   //  6  (0000 0110)
    printf("%d\n", ~b1);        // -13
    printf("%d\n", b1 << 1);   // 24  (0001 1000)
    printf("%d\n", b1 >> 1);   //  6  (0000 0110)
    printf("%d\n", b1 << 2);   // 48
    printf("%d\n", b1 >> 2);   //  3
    // 實際應用：位元遮罩
    int flags; flags = 0;
    flags = flags | 1;    printf("%d\n", flags);   // 1
    flags = flags | 4;    printf("%d\n", flags);   // 5
    flags = flags & 4;    printf("%d\n", flags);   // 4
    flags = flags ^ 4;    printf("%d\n", flags);   // 0

    return 0;
}
