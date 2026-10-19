#include <stdio.h>

int main(void)
{
    const double pi = 3.14159;
    double radio = 0.0;

    scanf("%lf", &radio);

    double area = pi * radio * radio;
    double perimetro = pi * radio;

    printf("Área: %.2f\n", area);
    printf("Perímetro: %.2f\n", perimetro);
    return 0;
}
