// test2.c
// 測試：while loop、for loop、break/continue、nested if

int main() {
    // for loop：印出 1~10，跳過偶數
    int i;
    for (i = 1; i <= 10; i++) {
        if (i % 2 == 0) {
            continue;
        }
        printf("odd: %d\n", i);
    }

    // while loop + break：找第一個能被 7 整除的數
    int n;
    n = 1;
    while (n <= 100) {
        if (n % 7 == 0) {
            printf("First multiple of 7: %d\n", n);
            break;
        }
        n++;
    }

    // 巢狀 if
    int score;
    score = 85;
    if (score >= 90) {
        printf("Grade: A\n");
    } else {
        if (score >= 80) {
            printf("Grade: B\n");
        } else {
            if (score >= 70) {
                printf("Grade: C\n");
            } else {
                printf("Grade: F\n");
            }
        }
    }

    // do-while：倒數
    int count;
    count = 5;
    do {
        printf("Countdown: %d\n", count);
        count--;
    } while (count > 0);

    return 0;
}
