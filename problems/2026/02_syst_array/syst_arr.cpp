// Matrix multiplication for systolic array testbench.
#include <iostream>
extern "C" {
    void mat_mul (int a[4][4], int b[4][4]) {
        int res[2][2];
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                res[i][j] = 0;
                for (int k = 0; k < 4; k++) {
                    res[i][j] += a[i][k] * b[k][j];
                }
                printf("%d\t", res[i][j]);
            }
        }
    }
}
