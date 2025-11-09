// Matrix multiplication for systolic array testbench.
#include <iostream>
extern "C" {
    void mat_mul (int a[2][2], int b[2][2]) {
        int res[2][2];
        for (int i = 0; i < 2; i++) {
            for (int j = 0; j < 2; j++) {
                res[i][j] = 0;
                for (int k = 0; k < 2; k++) {
                    res[i][j] += a[i][k] * b[k][j];
                }
                printf("%d\t", res[i][j]);
            }
        }

    }

}

