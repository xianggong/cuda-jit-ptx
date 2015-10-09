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
  CUmodule cudaModule;
  CUmodule cudaModule1;
  CUcontext context;
  CUfunction function;
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

  std::ifstream t("kernel.ptx");
  if (!t.is_open()) {
    std::cerr << "kernel.ptx not found\n";
    return 1;
  }
  std::string str((std::istreambuf_iterator<char>(t)),
                  std::istreambuf_iterator<char>());

  // Create driver context
  checkCudaResults(cuCtxCreate(&context, 0, device));

  // Create module for object
  checkCudaResults(cuModuleLoadDataEx(&cudaModule, str.c_str(), 0, 0, 0));

  // Get kernel functions
  checkCudaResults(cuModuleGetFunction(&function, cudaModule, "kernel"));

  unsigned dataCount = atoi(argv[1]);

  // Device data
  CUdeviceptr devBufferA;
  CUdeviceptr devBufferB;
  CUdeviceptr devBufferC;
  CUdeviceptr devBufferTidX;
  CUdeviceptr devBufferTidY;
  CUdeviceptr devBufferTidZ;
  CUdeviceptr devBufferNtidX;
  CUdeviceptr devBufferNtidY;
  CUdeviceptr devBufferNtidZ;
  CUdeviceptr devBufferLaneid;
  CUdeviceptr devBufferWarpid;
  CUdeviceptr devBufferNwarpid;
  CUdeviceptr devBufferCtaidX;
  CUdeviceptr devBufferCtaidY;
  CUdeviceptr devBufferCtaidZ;
  CUdeviceptr devBufferNctaidX;
  CUdeviceptr devBufferNctaidY;
  CUdeviceptr devBufferNctaidZ;
  CUdeviceptr devBufferSMid;
  CUdeviceptr devBufferNsmid;
  CUdeviceptr devBufferGridid;
  CUdeviceptr devBufferClock;

  checkCudaResults(cuMemAlloc(&devBufferA, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferB, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferC, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferTidX, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferTidY, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferTidZ, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNtidX, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNtidY, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNtidZ, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferLaneid, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferWarpid, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNwarpid, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferCtaidX, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferCtaidY, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferCtaidZ, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNctaidX, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNctaidY, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNctaidZ, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferSMid, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferNsmid, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferGridid, sizeof(int) * dataCount));
  checkCudaResults(cuMemAlloc(&devBufferClock, sizeof(int) * dataCount));

  float* hostA = new float[dataCount];
  float* hostB = new float[dataCount];
  float* hostC = new float[dataCount];
  int* hostTidX = new int[dataCount];
  int* hostTidY = new int[dataCount];
  int* hostTidZ = new int[dataCount];
  int* hostNtidX = new int[dataCount];
  int* hostNtidY = new int[dataCount];
  int* hostNtidZ = new int[dataCount];
  int* hostLaneid = new int[dataCount];
  int* hostWarpid = new int[dataCount];
  int* hostNwarpid = new int[dataCount];
  int* hostCtaidX = new int[dataCount];
  int* hostCtaidY = new int[dataCount];
  int* hostCtaidZ = new int[dataCount];
  int* hostNctaidX = new int[dataCount];
  int* hostNctaidY = new int[dataCount];
  int* hostNctaidZ = new int[dataCount];
  int* hostSMid = new int[dataCount];
  int* hostNsmid = new int[dataCount];
  int* hostGridid = new int[dataCount];
  int* hostClock = new int[dataCount];

  // Populate input
  for (unsigned i = 0; i != dataCount; ++i) {
    hostA[i] = (float)i;
    hostB[i] = (float)i;
    hostC[i] = 0.0f;
    hostTidX[i] = 0;
    hostTidY[i] = 0;
    hostTidZ[i] = 0;
    hostNtidX[i] = 0;
    hostNtidY[i] = 0;
    hostNtidZ[i] = 0;
    hostLaneid[i] = 0;
    hostWarpid[i] = 0;
    hostNwarpid[i] = 0;
    hostCtaidX[i] = 0;
    hostCtaidY[i] = 0;
    hostCtaidZ[i] = 0;
    hostNctaidX[i] = 0;
    hostNctaidY[i] = 0;
    hostNctaidZ[i] = 0;
    hostSMid[i] = 0;
    hostNsmid[i] = 0;
    hostGridid[i] = 0;
    hostClock[i] = 0;
  }

  // Data to GPU
  checkCudaResults(
      cuMemcpyHtoD(devBufferA, &hostA[0], sizeof(float) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferB, &hostB[0], sizeof(float) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferC, &hostC[0], sizeof(float) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferTidX, &hostTidX[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferTidY, &hostTidY[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferTidZ, &hostTidZ[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNtidX, &hostNtidX[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNtidY, &hostNtidY[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNtidZ, &hostNtidZ[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferLaneid, &hostLaneid[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferWarpid, &hostWarpid[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNwarpid, &hostNwarpid[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferCtaidX, &hostCtaidX[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferCtaidY, &hostCtaidY[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferCtaidZ, &hostCtaidZ[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNctaidX, &hostNctaidX[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNctaidY, &hostNctaidY[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNctaidZ, &hostNctaidZ[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferSMid, &hostSMid[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferNsmid, &hostNsmid[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferGridid, &hostGridid[0], sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyHtoD(devBufferClock, &hostClock[0], sizeof(int) * dataCount));

  unsigned blockSizeX = atoi(argv[2]);
  unsigned blockSizeY = 1;
  unsigned blockSizeZ = 1;
  unsigned gridSizeX = (dataCount + blockSizeX - 1) / blockSizeX;
  unsigned gridSizeY = 1;
  unsigned gridSizeZ = 1;

  // Kernel parameters
  void* KernelParams[] = {
      &devBufferA,       &devBufferB,       &devBufferC,      &devBufferTidX,
      &devBufferTidY,    &devBufferTidZ,    &devBufferNtidX,  &devBufferNtidY,
      &devBufferNtidZ,   &devBufferLaneid,  &devBufferWarpid, &devBufferNwarpid,
      &devBufferCtaidX,  &devBufferCtaidY,  &devBufferCtaidZ, &devBufferNctaidX,
      &devBufferNctaidY, &devBufferNctaidZ, &devBufferSMid,   &devBufferNsmid,
      &devBufferGridid,  &devBufferClock};

  std::cout << "Launching kernel\n";

  // Kernel launch
  checkCudaResults(cuLaunchKernel(function, gridSizeX, gridSizeY, gridSizeZ,
                                  blockSizeX, blockSizeY, blockSizeZ, 0, 0,
                                  KernelParams, NULL));

  // Retrieve device data
  checkCudaResults(
      cuMemcpyDtoH(&hostC[0], devBufferC, sizeof(float) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostTidX[0], devBufferTidX, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostTidY[0], devBufferTidY, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostTidZ[0], devBufferTidZ, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNtidX[0], devBufferNtidX, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNtidY[0], devBufferNtidY, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNtidZ[0], devBufferNtidZ, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostLaneid[0], devBufferLaneid, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostWarpid[0], devBufferWarpid, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNwarpid[0], devBufferNwarpid, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostCtaidX[0], devBufferCtaidX, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostCtaidY[0], devBufferCtaidY, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostCtaidZ[0], devBufferCtaidZ, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNctaidX[0], devBufferNctaidX, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNctaidY[0], devBufferNctaidY, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNctaidZ[0], devBufferNctaidZ, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostSMid[0], devBufferSMid, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostNsmid[0], devBufferNsmid, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostGridid[0], devBufferGridid, sizeof(int) * dataCount));
  checkCudaResults(
      cuMemcpyDtoH(&hostClock[0], devBufferClock, sizeof(int) * dataCount));

  std::cout << "Kernel results:\n";
  std::cout << "A\t"
            << "B\t"
            << "C\t"
            << "TidX\t"
            << "TidY\t"
            << "TidZ\t"
            << "NtidX\t"
            << "NtidY\t"
            << "NtidZ\t"
            << "Laneid\t"
            << "Warpid\t"
            << "Nwarpid\t"
            << "CtaidX\t"
            << "CtaidY\t"
            << "CtaidZ\t"
            << "NctaidX\t"
            << "NctaidY\t"
            << "NctaidZ\t"
            << "SMid\t"
            << "Nsmid\t"
            << "Gridid\t"
            << "Clock\n";
  for (unsigned i = 1; i != dataCount; i++) {
    std::cout << hostA[i] << "\t" << hostB[i] << "\t" << hostC[i] << "\t"
              << hostTidX[i] << "\t" << hostTidY[i] << "\t" << hostTidZ[i]
              << "\t" << hostNtidX[i] << "\t" << hostNtidY[i] << "\t"
              << hostNtidZ[i] << "\t" << hostLaneid[i] << "\t" << hostWarpid[i]
              << "\t" << hostNwarpid[i] << "\t" << hostCtaidX[i] << "\t"
              << hostCtaidY[i] << "\t" << hostCtaidZ[i] << "\t"
              << hostNctaidX[i] << "\t" << hostNctaidY[i] << "\t"
              << hostNctaidZ[i] << "\t" << hostSMid[i] << "\t" << hostNsmid[i]
              << "\t" << hostGridid[i] << "\t" << hostClock[i] << "\n";
  }

  // Clean up after ourselves
  delete[] hostA;
  delete[] hostB;
  delete[] hostC;
  delete[] hostTidX;
  delete[] hostTidY;
  delete[] hostTidZ;
  delete[] hostNtidX;
  delete[] hostNtidY;
  delete[] hostNtidZ;
  delete[] hostLaneid;
  delete[] hostWarpid;
  delete[] hostNwarpid;
  delete[] hostCtaidX;
  delete[] hostCtaidY;
  delete[] hostCtaidZ;
  delete[] hostNctaidX;
  delete[] hostNctaidY;
  delete[] hostNctaidZ;
  delete[] hostSMid;
  delete[] hostNsmid;
  delete[] hostGridid;
  delete[] hostClock;

  // Clean-up
  checkCudaResults(cuMemFree(devBufferA));
  checkCudaResults(cuMemFree(devBufferB));
  checkCudaResults(cuMemFree(devBufferC));
  checkCudaResults(cuMemFree(devBufferTidX));
  checkCudaResults(cuMemFree(devBufferTidY));
  checkCudaResults(cuMemFree(devBufferTidZ));
  checkCudaResults(cuMemFree(devBufferNtidX));
  checkCudaResults(cuMemFree(devBufferNtidY));
  checkCudaResults(cuMemFree(devBufferNtidZ));
  checkCudaResults(cuMemFree(devBufferLaneid));
  checkCudaResults(cuMemFree(devBufferWarpid));
  checkCudaResults(cuMemFree(devBufferNwarpid));
  checkCudaResults(cuMemFree(devBufferCtaidX));
  checkCudaResults(cuMemFree(devBufferCtaidY));
  checkCudaResults(cuMemFree(devBufferCtaidZ));
  checkCudaResults(cuMemFree(devBufferNctaidX));
  checkCudaResults(cuMemFree(devBufferNctaidY));
  checkCudaResults(cuMemFree(devBufferNctaidZ));
  checkCudaResults(cuMemFree(devBufferSMid));
  checkCudaResults(cuMemFree(devBufferNsmid));
  checkCudaResults(cuMemFree(devBufferGridid));
  checkCudaResults(cuMemFree(devBufferClock));

  checkCudaResults(cuModuleUnload(cudaModule));
  checkCudaResults(cuCtxDestroy(context));

  return 0;
}
