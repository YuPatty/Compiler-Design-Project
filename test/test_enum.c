// test_enum.c
// 測試：列舉型別 enum（含自訂值、編譯期零讀取）

enum Direction { NORTH, SOUTH, EAST, WEST };
enum Color { RED = 1, GREEN = 2, BLUE = 4 };
enum Status { OK = 200, CREATED = 201, NOT_FOUND = 404, ERROR = 500 };
enum Bool { FALSE_VAL = 0, TRUE_VAL = 1 };

void print_direction(int d) {
    if (d == NORTH) printf("Direction: NORTH\n");
    else if (d == SOUTH) printf("Direction: SOUTH\n");
    else if (d == EAST)  printf("Direction: EAST\n");
    else printf("Direction: WEST\n");
}

int main(void) {
    printf("=== 基本 enum（自動編號）===\n");
    printf("NORTH=%d SOUTH=%d EAST=%d WEST=%d\n",
           NORTH, SOUTH, EAST, WEST);  // 0 1 2 3

    printf("=== enum 自訂值 ===\n");
    printf("RED=%d GREEN=%d BLUE=%d\n", RED, GREEN, BLUE);  // 1 2 4

    printf("=== HTTP Status enum ===\n");
    printf("OK=%d CREATED=%d NOT_FOUND=%d ERROR=%d\n",
           OK, CREATED, NOT_FOUND, ERROR);  // 200 201 404 500

    printf("=== enum 當變數使用 ===\n");
    int dir;
    dir = EAST;
    print_direction(dir);  // Direction: EAST

    printf("=== enum 在 switch-case ===\n");
    int status;
    status = NOT_FOUND;
    if (status == OK) {
        printf("Status: OK\n");
    } else if (status == NOT_FOUND) {
        printf("Status: NOT_FOUND (404)\n");
    } else {
        printf("Status: OTHER\n");
    }

    printf("=== enum 位元旗標操作 ===\n");
    int color_flags;
    color_flags = RED | BLUE;   // 1 | 4 = 5
    printf("RED|BLUE = %d\n", color_flags);  // 5
    int has_green;
    has_green = (color_flags & GREEN) != 0;
    printf("has GREEN: %d\n", has_green);    // 0

    printf("=== enum 零讀取優化驗證 ===\n");
    // enum 常數直接替換為整數，不產生 load 指令
    int sum;
    sum = NORTH + SOUTH + EAST + WEST;  // 0+1+2+3 = 6
    printf("N+S+E+W = %d\n", sum);       // 6

    return 0;
}
