// test_final_features.c
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

struct Processor {
    int line_count;
    int digit_count;
    int alpha_count;
    int alnum_count;
    int space_count;
    int upper_count;
    int lower_count;
    int print_count;
    int punct_count;
    int char_count;
};

int main() {
    struct Processor proc;
    struct Processor *p = &proc;
    
    p->line_count = 0; p->digit_count = 0; p->alpha_count = 0;
    p->alnum_count = 0; p->space_count = 0; p->upper_count = 0;
    p->lower_count = 0; p->print_count = 0; p->punct_count = 0;
    p->char_count = 0;

    printf("=== Stage 1: Writing data ===\n");
    char *fw = fopen("advance_io_test.txt", "w");
    if (fw == 0) { exit(1); }
    
    fprintf(fw, "Line 1: A+B=C! @2026\n");
    fprintf(fw, "  #Test_2: \t xyz\n");
    fclose(fw);

    printf("=== Stage 2: Reading & ctype.h Testing ===\n");
    char *fr = fopen("advance_io_test.txt", "r");
    if (fr == 0) { exit(1); }

    char buffer[100];
    
    while (feof(fr) == 0) {
        if (fgets(buffer, 100, fr) != 0) {
            p->line_count = p->line_count + 1;
            
            // 提早印出前綴
            printf("CASE SWAPPED: ");
            
            // ✨ 迴避陷阱：先將陣列元素提取到變數中，再進行運算
            int i = 0;
            char c = buffer[i]; 
            int ci = c; // 安全升級成整數
            
            // 迴圈條件改用純變數，完美避開陣列 sext 錯誤
            while (ci != 0) { 
                
                if (isdigit(ci)) p->digit_count = p->digit_count + 1;
                if (isalpha(ci)) p->alpha_count = p->alpha_count + 1;
                if (isalnum(ci)) p->alnum_count = p->alnum_count + 1;
                if (isspace(ci)) p->space_count = p->space_count + 1;
                if (isupper(ci)) p->upper_count = p->upper_count + 1;
                if (islower(ci)) p->lower_count = p->lower_count + 1;
                if (isprint(ci)) p->print_count = p->print_count + 1;
                if (ispunct(ci)) p->punct_count = p->punct_count + 1;
                
                // ✨ 迴避陷阱：直接用 putchar 印出轉換結果，不存回陣列
                if (islower(ci)) {
                    putchar(toupper(ci));
                } else if (isupper(ci)) {
                    putchar(tolower(ci));
                } else {
                    putchar(ci);
                }
                
                p->char_count = p->char_count + 1;
                i = i + 1;
                
                // 在迴圈最後才安全地拿取下一個字元
                c = buffer[i]; 
                ci = c;        
            }
        }
    }
    fclose(fr);
    
    printf("\n=== Stage 3: Struct Pointer (->) & Results ===\n");
    printf("Total Lines: %d\n", p->line_count);
    printf("Total Chars: %d\n", p->char_count);
    printf("--- ctype.h Stats ---\n");
    printf("Digits: %d\n", p->digit_count);
    printf("Alphas (Letters): %d\n", p->alpha_count);
    printf("Alnums (Letters+Digits): %d\n", p->alnum_count);
    printf("Spaces (including \\n, \\t): %d\n", p->space_count);
    printf("Uppers: %d\n", p->upper_count);
    printf("Lowers: %d\n", p->lower_count);
    printf("Puncts (Symbols): %d\n", p->punct_count);
    printf("Prints (Printable): %d\n", p->print_count);

    printf("\nTesting exit(0)...\n");
    exit(0);
    
    printf("FAIL: You should not see this line!\n");
    return 0;
}