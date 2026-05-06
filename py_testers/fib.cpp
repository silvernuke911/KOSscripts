#include <stdio.h>
#include <math.h>
#include <time.h>  // Add this for timing

int main(){
    clock_t start, end;  // For storing start and end times
    double cpu_time_used;
    
  
    
    double a;
    double c = 0;
    scanf("%lf",&a);
    start = clock();  // Start timing
    if (a < 0) {
        printf("Cannot compute square root of negative number!\n");
        return 1;
    }
    
    double b = a/2;

    while (fabs(b-c) > 1e-15) {
        c = b;
        b = (b + a/b)/2;
        // printf("%.15f\t%.15f\n",b, b*b);
    }
    
    
    end = clock();  // End timing
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
    
    printf("\n");
    printf("%.15f\t%.15f\n",b,a);
    printf("\nExecution time: %.6f seconds\n", cpu_time_used);  // Show timing
    
    return 0;
}