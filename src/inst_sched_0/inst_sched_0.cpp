#include <iostream>
#include <fstream>
#include <cassert>
#include "cuda.h"

inline void checkCudaErrors(CUresult err) { assert(err == CUDA_SUCCESS); }

/// main - Program entry point
int main(int argc, char** argv) {
  if (argc != 3) {
    printf("Usage: %s dataCount blockSize\n", argv[0]);
    exit(1);
  }

  CUdevice device;
  CUmodule cudaModule;
  CUcontext context;
  CUfunction function;
  CUlinkState linker;
  int devCount;

  // CUDA initialization
  checkCudaErrors(cuInit(0));
  checkCudaErrors(cuDeviceGetCount(&devCount));
  checkCudaErrors(cuDeviceGet(&device, 0));

  char name[128];
  checkCudaErrors(cuDeviceGetName(name, 128, device));
  std::cout << "Using CUDA Device [0]: " << name << "\n";

  int devMajor, devMinor;
  checkCudaErrors(cuDeviceComputeCapability(&devMajor, &devMinor, device));
  std::cout << "Device Compute Capability: " << devMajor << "." << devMinor
            << "\n";
  if (devMajor < 2) {
    std::cerr << "ERROR: Device 0 is not SM 2.0 or greater\n";
    return 1;
  }

  std::ifstream t("kernel.ptx");
  if (!t.is_open()) {
    std::cerr << "kernel.ptx not found\n";
    return 1;
  }
  std::string str((std::istreambuf_iterator<char>(t)),
                  std::istreambuf_iterator<char>());

  // Create driver context
  checkCudaErrors(cuCtxCreate(&context, 0, device));

  // Create module for object
  checkCudaErrors(cuModuleLoadDataEx(&cudaModule, str.c_str(), 0, 0, 0));

  // Get kernel function
  checkCudaErrors(cuModuleGetFunction(&function, cudaModule, "kernel"));

  // Device data
  CUdeviceptr devBufferA;
  CUdeviceptr devBufferB;
  CUdeviceptr devBufferC;
  CUdeviceptr devBufferSMid;

  // Size
  unsigned dataCount = atoi(argv[1]);

  checkCudaErrors(cuMemAlloc(&devBufferA, sizeof(float) * dataCount));
  checkCudaErrors(cuMemAlloc(&devBufferB, sizeof(float) * dataCount));
  checkCudaErrors(cuMemAlloc(&devBufferC, sizeof(float) * dataCount));
  checkCudaErrors(cuMemAlloc(&devBufferSMid, sizeof(int) * dataCount));

  float* hostA = new float[dataCount];
  float* hostB = new float[dataCount];
  float* hostC = new float[dataCount];
  int* hostSMid = new int[dataCount];

  // Populate input
  for (unsigned i = 0; i != dataCount; ++i) {
    hostA[i] = (float)i;
    hostB[i] = (float)(2 * i);
    hostC[i] = 2.0f;
    hostSMid[i] = 0;
  }

  checkCudaErrors(
      cuMemcpyHtoD(devBufferA, &hostA[0], sizeof(float) * dataCount));
  checkCudaErrors(
      cuMemcpyHtoD(devBufferB, &hostB[0], sizeof(float) * dataCount));

  unsigned blockSizeX = atoi(argv[2]);
  unsigned blockSizeY = 1;
  unsigned blockSizeZ = 1;
  unsigned gridSizeX = (dataCount + blockSizeX - 1) / blockSizeX;
  unsigned gridSizeY = 1;
  unsigned gridSizeZ = 1;

  // Kernel parameters
  void* KernelParams[] = {&devBufferA, &devBufferB, &devBufferC,
                          &devBufferSMid};

  std::cout << "Launching kernel\n";

  // Kernel launch
  checkCudaErrors(cuLaunchKernel(function, gridSizeX, gridSizeY, gridSizeZ,
                                 blockSizeX, blockSizeY, blockSizeZ, 0, NULL,
                                 KernelParams, NULL));

  // Retrieve device data
  checkCudaErrors(
      cuMemcpyDtoH(&hostC[0], devBufferC, sizeof(float) * dataCount));
  checkCudaErrors(
      cuMemcpyDtoH(&hostSMid[0], devBufferSMid, sizeof(int) * dataCount));

  std::cout << "Results:\n";
  std::cout << "SM " << hostSMid[0] << ":" << hostA[0] << " + " << hostB[0]
            << " = " << hostC[0] << "\n";
  for (unsigned i = 1; i != dataCount; i++) {
    if (hostSMid[i] != hostSMid[i - 1])
      std::cout << "SM " << hostSMid[i] << ":" << hostA[i] << " + " << hostB[i]
                << " = " << hostC[i] << "\n";
  }

  // Clean up after ourselves
  delete[] hostA;
  delete[] hostB;
  delete[] hostC;
  delete[] hostSMid;

  // Clean-up
  checkCudaErrors(cuMemFree(devBufferA));
  checkCudaErrors(cuMemFree(devBufferB));
  checkCudaErrors(cuMemFree(devBufferC));
  checkCudaErrors(cuMemFree(devBufferSMid));
  checkCudaErrors(cuModuleUnload(cudaModule));
  checkCudaErrors(cuCtxDestroy(context));

  return 0;
}
