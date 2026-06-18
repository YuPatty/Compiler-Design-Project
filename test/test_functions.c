/* =====================================================
   test_functions.c
   六、函式系統與標準庫
   1.  自訂函式、遞迴、多參數
   2.  前置宣告（Prototype）
   3.  char 整數提升（charPromote）
   4.  float → double varargs 提升
   5.  strlen / strcpy / strcat / strcmp
   6.  atoi / atof
   7.  sqrt / pow / fabs / floor / ceil / sin / cos / log
   8.  abs / fmod
   9.  getchar / putchar
   10. sprintf / snprintf
   11. scanf 支援 %s 讀字串
   12. void 函式 return; 正確產生 ret void
   ===================================================== */

/* ──────────────────────────────────────
   2. 前置宣告（Prototype）
   ────────────────────────────────────── */
int add(int a, int b);
int factorial(int n);
int fibonacci(int n);
float circle_area(float r);
void print_sep(char ch, int n);
int char_sum(char a, char b);
float avg3(float a, float b, float c);

/* ──────────────────────────────────────
   12. void 函式
   ────────────────────────────────────── */
void print_sep(char ch, int n) {
    int i;
    i = 0;
    while (i < n) {
        putchar(ch);
        i = i + 1;
    }
    putchar(10);
    return;
}

void do_nothing(void) {
    return;
}

/* ──────────────────────────────────────
   1. 自訂函式、多參數
   ────────────────────────────────────── */
int add(int a, int b) {
    return a + b;
}

int multiply(int a, int b, int c) {
    return a * b * c;
}

float circle_area(float r) {
    float pi;
    pi = 3.14159;
    return pi * r * r;
}

/* ──────────────────────────────────────
   1. 遞迴函式
   ────────────────────────────────────── */
int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

int fibonacci(int n) {
    if (n <= 0) return 0;
    if (n == 1) return 1;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

/* ──────────────────────────────────────
   3. char 整數提升
   ────────────────────────────────────── */
int char_sum(char a, char b) {
    return a + b;
}

int char_to_int(char c) {
    return c;
}

/* ──────────────────────────────────────
   4. float → double varargs 提升
   ────────────────────────────────────── */
float avg3(float a, float b, float c) {
    return (a + b + c) / 3.0;
}

/* ════════════════════════════════════════
   main
   ════════════════════════════════════════ */
int main(void) {

    /* ---------------------------------------------------
       1. 自訂函式、遞迴、多參數
       --------------------------------------------------- */
    printf("--- 1. Custom functions & recursion ---\n");

    int r1;
    r1 = add(3, 7);
    printf("add(3,7) = %d\n", r1);

    int r2;
    r2 = multiply(2, 3, 4);
    printf("multiply(2,3,4) = %d\n", r2);

    float area;
    area = circle_area(5.0);
    printf("circle_area(5.0) = %f\n", area);

    printf("factorial(0) = %d\n", factorial(0));
    printf("factorial(1) = %d\n", factorial(1));
    printf("factorial(5) = %d\n", factorial(5));
    printf("factorial(10) = %d\n", factorial(10));

    printf("fibonacci(0) = %d\n", fibonacci(0));
    printf("fibonacci(1) = %d\n", fibonacci(1));
    printf("fibonacci(7) = %d\n", fibonacci(7));
    printf("fibonacci(10) = %d\n", fibonacci(10));

    /* ---------------------------------------------------
       2. 前置宣告（Prototype）
       --------------------------------------------------- */
    printf("--- 2. Prototype ---\n");
    printf("add prototype: %d\n", add(10, 20));
    printf("factorial prototype: %d\n", factorial(6));
    printf("avg3 prototype: %f\n", avg3(1.0, 2.0, 3.0));

    /* ---------------------------------------------------
       3. char 整數提升（charPromote）
       --------------------------------------------------- */
    printf("--- 3. char promotion ---\n");

    char ca;
    char cb;
    ca = 'A';
    cb = 'a';
    printf("char_sum('A','a') = %d\n", char_sum(ca, cb));
    printf("char_to_int('A') = %d\n", char_to_int(ca));
    printf("char_to_int('0') = %d\n", char_to_int('0'));
    printf("char_to_int('z') = %d\n", char_to_int('z'));

    int diff;
    diff = cb - ca;
    printf("'a'-'A' = %d\n", diff);

    /* ---------------------------------------------------
       4. float → double varargs 提升（printf %f）
       --------------------------------------------------- */
    printf("--- 4. float->double varargs ---\n");

    float fv;
    fv = 3.14;
    printf("float 3.14 via %%f: %f\n", fv);

    float fv2;
    fv2 = 1.5e2;
    printf("float 1.5e2 via %%f: %f\n", fv2);

    float fv3;
    fv3 = -0.001;
    printf("float -0.001 via %%f: %f\n", fv3);

    printf("avg3(1.0,2.0,3.0) = %f\n", avg3(1.0, 2.0, 3.0));
    printf("avg3(0.1,0.2,0.3) = %f\n", avg3(0.1, 0.2, 0.3));

    /* ---------------------------------------------------
       5. strlen / strcpy / strcat / strcmp
       --------------------------------------------------- */
    printf("--- 5. string functions ---\n");

    char s1[64];
    char s2[64];
    char s3[128];

    s1 = "Hello";
    s2 = "World";

    int len1;
    len1 = strlen(s1);
    printf("strlen(Hello) = %d\n", len1);

    int len2;
    len2 = strlen(s2);
    printf("strlen(World) = %d\n", len2);

    strcpy(s3, s1);
    printf("strcpy: %s\n", s3);

    strcat(s3, " ");
    strcat(s3, s2);
    printf("strcat: %s\n", s3);

    int cmp1;
    cmp1 = strcmp(s1, s1);
    printf("strcmp(Hello,Hello) = %d\n", cmp1);

    int cmp2;
    cmp2 = strcmp(s1, s2);
    printf("strcmp(Hello,World)<0: %d\n", cmp2 < 0);

    int cmp3;
    cmp3 = strcmp(s2, s1);
    printf("strcmp(World,Hello)>0: %d\n", cmp3 > 0);

    /* ---------------------------------------------------
       6. atoi / atof
       --------------------------------------------------- */
    printf("--- 6. atoi / atof ---\n");

    char ns[32];
    ns = "42";
    int iv;
    iv = atoi(ns);
    printf("atoi(42) = %d\n", iv);

    ns = "-100";
    iv = atoi(ns);
    printf("atoi(-100) = %d\n", iv);

    ns = "0";
    iv = atoi(ns);
    printf("atoi(0) = %d\n", iv);

    char fs[32];
    fs = "3.14";
    float fv4;
    fv4 = atof(fs);
    printf("atof(3.14) = %f\n", fv4);

    fs = "2.718";
    fv4 = atof(fs);
    printf("atof(2.718) = %f\n", fv4);

    fs = "0.0";
    fv4 = atof(fs);
    printf("atof(0.0) = %f\n", fv4);

    /* ---------------------------------------------------
       7. sqrt / pow / fabs / floor / ceil / sin / cos / log
       --------------------------------------------------- */
    printf("--- 7. math functions ---\n");

    float m1;
    m1 = sqrt(4.0);
    printf("sqrt(4.0) = %f\n", m1);

    m1 = sqrt(2.0);
    printf("sqrt(2.0) = %f\n", m1);

    m1 = pow(2.0, 10.0);
    printf("pow(2,10) = %f\n", m1);

    m1 = pow(3.0, 3.0);
    printf("pow(3,3) = %f\n", m1);

    m1 = fabs(-3.14);
    printf("fabs(-3.14) = %f\n", m1);

    m1 = fabs(2.718);
    printf("fabs(2.718) = %f\n", m1);

    m1 = floor(3.9);
    printf("floor(3.9) = %f\n", m1);

    m1 = floor(-3.1);
    printf("floor(-3.1) = %f\n", m1);

    m1 = ceil(3.1);
    printf("ceil(3.1) = %f\n", m1);

    m1 = ceil(-3.9);
    printf("ceil(-3.9) = %f\n", m1);

    m1 = log(1.0);
    printf("log(1.0) = %f\n", m1);

    /* ---------------------------------------------------
       8. abs / fmod
       --------------------------------------------------- */
    printf("--- 8. abs / fmod ---\n");

    int ab1;
    ab1 = abs(-7);
    printf("abs(-7) = %d\n", ab1);

    ab1 = abs(0);
    printf("abs(0) = %d\n", ab1);

    ab1 = abs(5);
    printf("abs(5) = %d\n", ab1);

    float fm1;
    fm1 = fmod(10.0, 3.0);
    printf("fmod(10,3) = %f\n", fm1);

    fm1 = fmod(7.5, 2.5);
    printf("fmod(7.5,2.5) = %f\n", fm1);

    fm1 = fmod(-5.0, 2.0);
    printf("fmod(-5,2) = %f\n", fm1);

    /* ---------------------------------------------------
       9. getchar / putchar
       --------------------------------------------------- */
    printf("--- 9. putchar ---\n");

    putchar(72);
    putchar(101);
    putchar(108);
    putchar(108);
    putchar(111);
    putchar(10);

    char msg[8];
    msg = "ABCDE";
    int pi;
    pi = 0;
    while (pi < 5) {
        putchar(msg[pi]);
        pi = pi + 1;
    }
    putchar(10);

    /* ---------------------------------------------------
       10. sprintf / snprintf
       --------------------------------------------------- */
    printf("--- 10. sprintf / snprintf ---\n");

    char buf[64];
    int n;
    float fsp;
    n = 42;
    fsp = 3.14;

    sprintf(buf, "int=%d", n);
    printf("%s\n", buf);

    sprintf(buf, "float=%f", fsp);
    printf("%s\n", buf);

    sprintf(buf, "both: %d and %f", n, fsp);
    printf("%s\n", buf);

    char small[8];
    int limit;
    limit = 8;
    int written;
    written = snprintf(small, limit, "12345678");
    printf("written=%d result=%s\n", written, small);

    int lim2;
    lim2 = 16;
    char buf2[16];
    snprintf(buf2, lim2, "hello %d", 99);
    printf("%s\n", buf2);

    /* ---------------------------------------------------
       11. scanf 支援 %s 讀字串
       --------------------------------------------------- */
    printf("--- 11. scanf %%s ---\n");
    char word[32];
    printf("Enter word: ");
    scanf("%s", word);
    printf("Got: %s\n", word);
    printf("len=%d\n", strlen(word));

    /* ---------------------------------------------------
       12. void 函式 return; → ret void
       --------------------------------------------------- */
    printf("--- 12. void return ---\n");
    do_nothing();
    printf("do_nothing() returned\n");
    print_sep('=', 10);

    return 0;
}
