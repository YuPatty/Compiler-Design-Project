int main(){
    float big;
    big = 1234567.89;   // 右邊是 double，但被截斷存入 float
    printf("float 1234567.89 = %f\n", big);  // 印出 .875000

    double really_big;
    really_big = 1234567.89; // 右邊是 double，存入 double (無截斷)
    printf("double 1234567.89 = %f\n", really_big); // 將會完美印出 .890000
}