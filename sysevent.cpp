#include <stdint.h>
#include <inttypes.h>

#include <iostream>
#include <iomanip>

typedef struct{
  uint32_t ok_;
  uint32_t moderate_;
  uint32_t severe_;
} StorageTestResult; 

static
void STGTEST(StorageTestResult* result)
{
  __asm(" L 1,%0 \n"
        " SYSEVENT STGTEST \n"
        : 
        : "m"(result)
        : "r1 r15");
}

static
uint32_t FREEAUX()
{
  uint32_t result = 0;
  __asm("CVTPTR EQU 16 \n"
        "CVT EQU 0 \n"
        "CVTSRM EQU X'3E8' \n"
        " SYSEVENT FREEAUX \n"
        " ST 0,%0 \n"
        : "=m"(result)
        : 
        : "r1 r15");
  return result;
}

static
void printValue(const char* what, uint32_t value)
{
  using namespace std;
  cout << left << setw(10) << what << right << ": " << value << " (" << value/256 << " MB)" << endl;
}

int main(int argc, const char* const argv[])
{
  using namespace std;
  StorageTestResult result;
  result.ok_ = 1;
  result.moderate_ = 2;
  result.severe_ = 3;

  STGTEST(&result);
  cout << "Main storage available: " << endl;
  printValue("ok", result.ok_);
  printValue("moderate", result.moderate_);
  printValue("severe", result.severe_);
  uint32_t asmSlots = FREEAUX();
  printValue("ASM slots available", asmSlots);

  return 0;
}
