
extern int printf (__const char *__restrict __format, ...);
/* L'analyseur d�borde et dit i=-1 */
int main () {
  unsigned long long i = 0xFFFFFFFFFFFFFFFFULL;
  unsigned long j = 0xFFFFFFFFUL;

  long long is = 0xFFFFFFFFFFFFFFFFULL;
  long js =    0xFFFFFFFFUL;
  long minjs = - (j/2) -1  ;
  long maxjs =  j/2  ;
  
  unsigned long long i1 = i+1;
  unsigned long j1 = j+1;

  int y = 100000;
  int x = (60000 * y ) / 100000;
  printf("unsigned long long:%llu (+1:%llu)\nunsigned long:%lu (+1:%lu)\n"
         ,i,i1,j,j1);
  printf("signed long long:%lld (+1:%lld)\nlong:%ld (+1:%ld)\n"
         ,is,is+1,js,js+1);
  printf("min signed long:%ld (-1:%ld)\n"
         ,minjs,minjs-1L);

  return 0;
}
