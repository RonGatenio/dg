#include <pthread.h>
#include <immintrin.h>
// #include "sec.h"

#define FLUSH(addr) _mm_clflush((void*)(addr))

#define FLUSHFENCE()  _mm_sfence()

volatile int GlobalX = 0;
volatile int GlobalY = 0;

void *Thread1(void *x) {
  // R(X)
  int temp = GlobalX;

  // W(Y)
  GlobalY = temp + 1;

  // F(Y)
  FLUSH(&GlobalY);
  FLUSHFENCE();
  
  return NULL;
}

void *Thread2(void *x) {
  // W(X)
  GlobalX = (1);

  // F(X)
  FLUSH(&GlobalX);
  FLUSHFENCE();
  
  return NULL;
}

void example_01_cross_dep(int x, int* y)
{
  *y = x;
}

void example_02_loop(int* x, int* y, size_t n)
{
  for (size_t i = 0; i < n; i++)
  {
    y[i] = x[i];
  }
}

void example_03_control_dep(int x, int* y)
{
  if (x > 5)
  {
    *y = 3;
  }
}

#define COUNTOF(arr) sizeof((arr))/sizeof((arr)[0])

volatile int x = 1;
volatile int y = 0;

volatile int arr_x[] = {0,1,2,3,4,5};
volatile int arr_y[sizeof(arr_x)] = {0};

int main() {
    void* thread_funcs[] = {Thread1, Thread2};
    pthread_t t1, t2;
    
    pthread_create(&t1, NULL, Thread1, NULL);
    pthread_create(&t2, NULL, Thread2, NULL);
    
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);

    example_01_cross_dep(x, &y);

    example_03_control_dep(x, &y);

    example_02_loop(arr_x, arr_y, sizeof(arr_x));
    
    return 0;
}
