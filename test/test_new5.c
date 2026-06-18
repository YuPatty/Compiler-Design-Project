int main(void) {

    /* =====================================================
       TEST 1: sprintf
       ===================================================== */
    printf("--- 1. sprintf ---\n");
    char buf1[64];
    int n;
    float f;
    n = 42;
    f = 3.14;

    sprintf(buf1, "int=%d", n);
    printf("%s\n", buf1);

    sprintf(buf1, "float=%f", f);
    printf("%s\n", buf1);

    sprintf(buf1, "both: %d and %f", n, f);
    printf("%s\n", buf1);

    /* =====================================================
       TEST 2: snprintf (有長度限制)
       ===================================================== */
    printf("--- 2. snprintf ---\n");
    char buf2[16];
    int maxLen;
    maxLen = 16;
    snprintf(buf2, maxLen, "hello %d", 99);
    printf("%s\n", buf2);

    int smallLen;
    smallLen = 5;
    snprintf(buf2, smallLen, "toolongstring");
    printf("%s\n", buf2);

    /* =====================================================
       TEST 3: atoi (字串轉整數)
       ===================================================== */
    printf("--- 3. atoi ---\n");
    char s1[16];
    s1 = "123";
    int v1;
    v1 = atoi(s1);
    printf("atoi 123 = %d\n", v1);

    s1 = "-456";
    int v2;
    v2 = atoi(s1);
    printf("atoi -456 = %d\n", v2);

    s1 = "0";
    int v3;
    v3 = atoi(s1);
    printf("atoi 0 = %d\n", v3);

    /* =====================================================
       TEST 4: atof (字串轉浮點數)
       ===================================================== */
    printf("--- 4. atof ---\n");
    char s2[32];
    s2 = "3.14";
    float fv1;
    fv1 = atof(s2);
    printf("atof 3.14 = %f\n", fv1);

    s2 = "2.718";
    float fv2;
    fv2 = atof(s2);
    printf("atof 2.718 = %f\n", fv2);

    s2 = "0.0";
    float fv3;
    fv3 = atof(s2);
    printf("atof 0.0 = %f\n", fv3);

    /* =====================================================
       TEST 5: abs (整數絕對值)
       ===================================================== */
    printf("--- 5. abs ---\n");
    int a1;
    int a2;
    int a3;
    a1 = abs(-7);
    a2 = abs(0);
    a3 = abs(5);
    printf("abs(-7) = %d\n", a1);
    printf("abs(0) = %d\n", a2);
    printf("abs(5) = %d\n", a3);

    int neg;
    neg = -100;
    printf("abs(-100) = %d\n", abs(neg));

    /* =====================================================
       TEST 6: fmod (浮點取餘數)
       ===================================================== */
    printf("--- 6. fmod ---\n");
    float fm1;
    float fm2;
    float fm3;
    fm1 = fmod(10.0, 3.0);
    printf("fmod(10,3) = %f\n", fm1);

    fm2 = fmod(7.5, 2.5);
    printf("fmod(7.5,2.5) = %f\n", fm2);

    fm3 = fmod(-5.0, 2.0);
    printf("fmod(-5,2) = %f\n", fm3);

    /* =====================================================
       TEST 7: CSE (公共子式消除)
       ===================================================== */
    printf("--- 7. CSE ---\n");
    int x;
    int y;
    x = 6;
    y = 4;

    int r1;
    int r2;
    int r3;
    r1 = x + y;
    r2 = x + y;
    r3 = x + y;
    printf("x+y = %d\n", r1);
    printf("x+y = %d\n", r2);
    printf("x+y = %d\n", r3);

    float fx;
    float fy;
    fx = 2.0;
    fy = 3.0;
    float fr1;
    float fr2;
    fr1 = fx * fy;
    fr2 = fx * fy;
    printf("fx*fy = %f\n", fr1);
    printf("fx*fy = %f\n", fr2);

    int big;
    big = (x + y) * (x + y);
    printf("(x+y)^2 = %d\n", big);

    /* =====================================================
       TEST 8: 字串字面值賦值給 char 陣列
       ===================================================== */
    printf("--- 8. String literal assign ---\n");
    char str1[32];
    str1 = "Hello, World!";
    printf("%s\n", str1);

    char str2[32];
    str2 = "ANTLR compiler";
    printf("%s\n", str2);

    char str4[32];
    str4 = "line1";
    printf("str4 = %s\n", str4);
    str4 = "line2";
    printf("str4 = %s\n", str4);

    /* =====================================================
       TEST 9: 組合使用 (sprintf + atoi + abs)
       ===================================================== */
    printf("--- 9. Combined ---\n");
    char numStr[32];
    sprintf(numStr, "%d", -99);
    printf("sprintf -> %s\n", numStr);

    int parsed;
    parsed = atoi(numStr);
    printf("atoi -> %d\n", parsed);

    int absVal;
    absVal = abs(parsed);
    printf("abs -> %d\n", absVal);

    char fStr[32];
    sprintf(fStr, "%f", 1.5);
    printf("sprintf float -> %s\n", fStr);
    float parsedF;
    parsedF = atof(fStr);
    printf("atof -> %f\n", parsedF);

    /* =====================================================
       TEST 10: snprintf 截斷行為
       ===================================================== */
    printf("--- 10. snprintf truncation ---\n");
    char small[8];
    int written;
    int limit;
    limit = 8;
    written = snprintf(small, limit, "12345678");
    printf("written=%d result=%s\n", written, small);

    return 0;
}