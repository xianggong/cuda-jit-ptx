#include <iostream>
#include <fstream>
#include <cassert>
#include "cuda.h"
#include "cuda_runtime.h"

void checkCudaResults(CUresult rslt) { assert(rslt == CUDA_SUCCESS); }
void checkCudaErrors(cudaError err) { assert(err == cudaSuccess); }

/// main - Program entry point
int main(int argc, char** argv) {
  if (argc != 3) {
    printf("Usage: %s dataCount blockSize\n", argv[0]);
    exit(1);
  }

  CUdevice device;
  CUmodule cudaModule0;
  CUmodule cudaModule1;
  CUcontext context;
  CUfunction function0;
  CUfunction function1;
  CUlinkState linker;
  int devCount;

  // CUDA initialization
  checkCudaResults(cuInit(0));
  checkCudaResults(cuDeviceGetCount(&devCount));
  checkCudaResults(cuDeviceGet(&device, 0));

  char name[128];
  checkCudaResults(cuDeviceGetName(name, 128, device));
  std::cout << "Using CUDA Device [0]: " << name << "\n";

  int devMajor, devMinor;
  checkCudaResults(cuDeviceComputeCapability(&devMajor, &devMinor, device));
  std::cout << "Device Compute Capability: " << devMajor << "." << devMinor
            << "\n";
  if (devMajor < 2) {
    std::cerr << "ERROR: Device 0 is not SM 2.0 or greater\n";
    return 1;
  }

  std::ifstream t0("kernel0.ptx");
  if (!t0.is_open()) {
    std::cerr << "kernel0.ptx not found\n";
    return 1;
  }
  std::string str0((std::istreambuf_iterator<char>(t0)),
                   std::istreambuf_iterator<char>());

  std::ifstream t1("kernel1.ptx");
  if (!t1.is_open()) {
    std::cerr << "kernel1.ptx not found\n";
    return 1;
  }
  std::string str1((std::istreambuf_iterator<char>(t1)),
                   std::istreambuf_iterator<char>());

  // Create driver context
  checkCudaResults(cuCtxCreate(&context, 0, device));

  // Create module for object
  checkCudaResults(cuModuleLoadDataEx(&cudaModule0, str0.c_str(), 0, 0, 0));
  checkCudaResults(cuModuleLoadDataEx(&cudaModule1, str1.c_str(), 0, 0, 0));

  // Get kernel functions
  checkCudaResults(cuModuleGetFunction(&function0, cudaModule0, "kernel"));
  checkCudaResults(cuModuleGetFunction(&function1, cudaModule1, "kernel"));

  // Device data
  CUdeviceptr devBufferA0;
  CUdeviceptr devBufferB0;
  CUdeviceptr devBufferC0;
  CUdeviceptr devBufferSMid0;

  CUdeviceptr devBufferA1;
  CUdeviceptr devBufferB1;
  CUdeviceptr devBufferC1;
  CUdeviceptr devBufferSMid1;

  // Size
  unsigned dataCount = atoi(argv[1]);

  checkCudaResults(cuMemAlloc(&devBufferA0, sizeof(float) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferB0, sizeof(float) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferC0, sizeof(float) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferSMid0, sizeof(int) * dataCount));

  checkCudaResults(cuMemAlloc(&devBufferA1, sizeof(float) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferB1, sizeof(float) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferC1, sizeof(float) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferSMid1, sizeof(int) * dataCount));

  float* hostA0 = new float[dataCount];
  float* hostB0 = new float[dataCount];
  float* hostC0 = new float[dataCount];
  int* hostSMid0 = new int[dataCount];

  float* hostA1 = new float[dataCount];
  float* hostB1 = new float[dataCount];
  float* hostC1 = new float[dataCount];
  int* hostSMid1 = new int[dataCount];

  // Page lock memory
  checkCudaErrors(cudaHostRegister(hostA0, sizeof(float) * dataCount, 0));
  checkCudaErrors(cudaHostRegister(hostB0, sizeof(float) * dataCount, 0));
  checkCudaErrors(cudaHostRegister(hostC0, sizeof(float) * dataCount, 0));
  checkCudaErrors(cudaHostRegister(hostSMid0, sizeof(float) * dataCount, 0));
  checkCudaErrors(cudaHostRegister(hostA1, sizeof(float) * dataCount, 0));
  checkCudaErrors(cudaHostRegister(hostB1, sizeof(float) * dataCount, 0));
  checkCudaErrors(cudaHostRegister(hostC1, sizeof(float) * dataCount, 0));
  checkCudaErrors(cudaHostRegister(hostSMid1, sizeof(float) * dataCount, 0));

  // Populate input
  for (unsigned i = 0; i != dataCount; ++i) {
    hostA0[i] = (float)i;
    hostB0[i] = (float)(2 * i);
    hostC0[i] = 2.0f;
    hostSMid0[i] = 0;

    hostA1[i] = (float)i;
    hostB1[i] = (float)(2 * i);
    hostC1[i] = 2.0f;
    hostSMid1[i] = 0;
  }

  // CUDA streams
  cudaStream_t strm0;
  cudaStream_t strm1;

  checkCudaErrors(cudaStreamCreate(&strm0));
  checkCudaErrors(cudaStreamCreate(&strm1));

  // Data to GPU
  checkCudaResults(cuMemcpyHtoDAsync(devBufferA0, &hostA0[0],
                                    sizeof(float) * dataCount, strm0));
  checkCudaResults(cuMemcpyHtoDAsync(devBufferB0, &hostB0[0],
                                    sizeof(float) * dataCount, strm0));

  checkCudaResults(cuMemcpyHtoDAsync(devBufferA1, &hostA1[0],
                                    sizeof(float) * dataCount, strm1));
  checkCudaResults(cuMemcpyHtoDAsync(devBufferB1, &hostB1[0],
                                    sizeof(float) * dataCount, strm1));

  unsigned blockSizeX = atoi(argv[2]);
  unsigned blockSizeY = 1;
  unsigned blockSizeZ = 1;
  unsigned gridSizeX = (dataCount + blockSizeX - 1) / blockSizeX;
  unsigned gridSizeY = 1;
  unsigned gridSizeZ = 1;

  // Kernel parameters
  void* Kernel0Params[] = {&devBufferA0, &devBufferB0,
                           &devBufferC0, &devBufferSMid0};
  void* Kernel1Params[] = {&devBufferA1, &devBufferB1,
                           &devBufferC1, &devBufferSMid1};

  std::cout << "Launching kernel\n";

  // Kernel launch
  checkCudaResults(cuLaunchKernel(function0, gridSizeX, gridSizeY, gridSizeZ,
                                 blockSizeX, blockSizeY, blockSizeZ, 0, strm0,
                                 Kernel0Params, NULL));
  checkCudaResults(cuLaunchKernel(function1, gridSizeX, gridSizeY, gridSizeZ,
                                 blockSizeX, blockSizeY, blockSizeZ, 0, strm1,
                                 Kernel1Params, NULL));

  // Sync Stream
  cudaStreamSynchronize(strm0);
  cudaStreamSynchronize(strm1);

  // Retrieve device data
  checkCudaResults(cuMemcpyDtoHAsync(&hostC0[0], devBufferC0,
                                    sizeof(float) * dataCount, strm0));
  checkCudaResults(cuMemcpyDtoHAsync(&hostSMid0[0], devBufferSMid0,
                                    sizeof(int) * dataCount, strm0));
  checkCudaResults(cuMemcpyDtoHAsync(&hostC1[0], devBufferC1,
                                    sizeof(float) * dataCount, strm1));
  checkCudaResults(cuMemcpyDtoHAsync(&hostSMid1[0], devBufferSMid1,
                                    sizeof(int) * dataCount, strm1));

  std::cout << "Kernel 0 results:\n";
  std::cout << "SM " << hostSMid0[0] << ":" << hostA0[0] << " + " << hostB0[0]
            << " = " << hostC0[0] << "\n";
  for (unsigned i = 1; i != dataCount; i++) {
    if (hostSMid0[i] != hostSMid0[i - 1])
      std::cout << "SM " << hostSMid0[i] << ":" << hostA0[i] << " + "
                << hostB0[i] << " = " << hostC0[i] << "\n";
  }

  std::cout << "Kernel 1 results:\n";
  std::cout << "SM " << hostSMid1[0] << ":" << hostA1[0] << " + " << hostB1[0]
            << " = " << hostC1[0] << "\n";
  for (unsigned i = 1; i != dataCount; i++) {
    if (hostSMid1[i] != hostSMid1[i - 1])
      std::cout << "SM " << hostSMid1[i] << ":" << hostA1[i] << " + "
                << hostB1[i] << " = " << hostC1[i] << "\n";
  }

  // Clean up after ourselves
  delete[] hostA0;
  delete[] hostB0;
  delete[] hostC0;
  delete[] hostSMid0;
  delete[] hostA1;
  delete[] hostB1;
  delete[] hostC1;
  delete[] hostSMid1;

  cudaStreamDestroy(strm0);
  cudaStreamDestroy(strm1);

  // Clean-up
  checkCudaResults(cuMemFree(devBufferA0));
  checkCudaResults(cuMemFree(devBufferB0));
  checkCudaResults(cuMemFree(devBufferC0));
  checkCudaResults(cuMemFree(devBufferSMid0));
  checkCudaResults(cuMemFree(devBufferA1));
  checkCudaResults(cuMemFree(devBufferB1));
  checkCudaResults(cuMemFree(devBufferC1));
  checkCudaResults(cuMemFree(devBufferSMid1));
  checkCudaResults(cuModuleUnload(cudaModule0));
  checkCudaResults(cuModuleUnload(cudaModule1));
  checkCudaResults(cuCtxDestroy(context));

  return 0;
}
