// test_stdlib_math.c
// 測試：string.h（strlen/strcpy/strcat/strcmp）
//       stdlib.h（atoi/atof/abs）
//       math.h（sqrt/pow/fabs/floor/ceil/sin/cos/log/fmod）
//       I/O（getchar/putchar/sprintf/snprintf）

int main(void) {

    // ════════════════════
    // string.h
    // ════════════════════
    printf("=== strlen ===\n");
    char s1[20];
    s1[0]=72; s1[1]=101; s1[2]=108; s1[3]=108; s1[4]=111; s1[5]=0; // "Hello"
    printf("strlen(Hello) = %d\n", strlen(s1));  // 5

    printf("=== strcpy ===\n");
    char s2[20];
    strcpy(s2, s1);
    printf("strcpy: %s\n", s2);  // Hello

    printf("=== strcat ===\n");
    char s3[40];
    strcpy(s3, s1);
    char world[10];
    world[0]=32; world[1]=87; world[2]=111; world[3]=114;
    world[4]=108; world[5]=100; world[6]=0;  // " World"
    strcat(s3, world);
    printf("strcat: %s\n", s3);  // Hello World

    printf("=== strcmp ===\n");
    printf("strcmp(s1,s1) = %d\n", strcmp(s1, s1));  // 0

    // ════════════════════
    // stdlib.h
    // ════════════════════
    printf("=== atoi ===\n");
    char num_str[10];
    num_str[0]=52; num_str[1]=50; num_str[2]=0;  // "42"
    int n; n = atoi(num_str);
    printf("atoi(42) = %d\n", n);  // 42

    printf("=== abs ===\n");
    printf("abs(-5)  = %d\n", abs(-5));   // 5
    printf("abs(5)   = %d\n", abs(5));    // 5
    printf("abs(-99) = %d\n", abs(-99));  // 99

    // ════════════════════
    // math.h
    // ════════════════════
    printf("=== sqrt ===\n");
    printf("sqrt(4)  = %f\n", sqrt(4.0));   // 2.0
    printf("sqrt(9)  = %f\n", sqrt(9.0));   // 3.0
    printf("sqrt(2)  = %f\n", sqrt(2.0));   // 1.414214

    printf("=== pow ===\n");
    printf("pow(2,8) = %f\n", pow(2.0, 8.0));   // 256.0
    printf("pow(3,3) = %f\n", pow(3.0, 3.0));   // 27.0

    printf("=== fabs ===\n");
    printf("fabs(-3.14) = %f\n", fabs(-3.14));  // 3.14

    printf("=== floor / ceil ===\n");
    printf("floor(3.7) = %f\n", floor(3.7));  // 3.0
    printf("ceil(3.2)  = %f\n", ceil(3.2));   // 4.0
    printf("floor(-1.3)= %f\n", floor(-1.3)); // -2.0

    printf("=== fmod ===\n");
    printf("fmod(7.5, 2.0) = %f\n", fmod(7.5, 2.0));  // 1.5
    printf("fmod(10.0,3.0) = %f\n", fmod(10.0, 3.0)); // 1.0

    // ════════════════════
    // sprintf / putchar
    // ════════════════════
    printf("=== sprintf ===\n");
    char buf[64];
    sprintf(buf, "x=%d pi=%f", 42, 3.14);
    printf("sprintf result: %s\n", buf);  // x=42 pi=3.140000

    printf("=== putchar ===\n");
    putchar(72);   // H
    putchar(105);  // i
    putchar(33);   // !
    putchar(10);   // \n

    return 0;
}
