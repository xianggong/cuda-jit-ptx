cmake_minimum_required(VERSION 2.8)

# Disable source change and in source build
set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(cuda-jit-ptx)

if (DEFINED ENV{CUDA_HOME})
  set(CUDA_HOME "$ENV{CUDA_HOME}")
  set(CUDA_HOME "$ENV{CUDA_HOME}" CACHE PATH "Path to CUDA Toolkit.")
  set(PTXAS_BIN "${CUDA_HOME}/bin/ptxas" CACHE PATH "Path to ptxas.")
  set(CUOBJDUMP_BIN "${CUDA_HOME}/bin/cuobjdump" CACHE PATH "Path to cuobjdump.")
elseif (NOT DEFINED CUDA_HOME)
  # There was no CUDA_HOME explicitly given, so try to determine it from
  # locating nvcc in PATH.
  find_program(NVCC nvcc)
  if (NOT NVCC)
    message(FATAL_ERROR "CUDA_HOME not set, and could not find nvcc in "
                        "your PATH.  Please either set CUDA_HOME to a "
                        "installation path for the CUDA 6 Toolkit or "
                        "add nvcc to your PATH.")
  endif()
  get_filename_component(CUDA_HOME "${NVCC}" PATH)
  get_filename_component(CUDA_HOME "${CUDA_HOME}/.." ABSOLUTE)
  set(CUDA_HOME "${CUDA_HOME}" CACHE PATH "Path to CUDA Toolkit.")
  set(PTXAS_BIN "${CUDA_HOME}/bin/ptxas" CACHE PATH "Path to ptxas.")
  set(CUOBJDUMP_BIN "${CUDA_HOME}/bin/cuobjdump" CACHE PATH "Path to cuobjdump.")
  message(STATUS "Using ptxas: ${PTXAS_BIN}")
  message(STATUS "Using cuobjdump: ${CUOBJDUMP_BIN}")
endif()

message(STATUS "Using CUDA_HOME: ${CUDA_HOME}")

# LLVM
if(DEFINED ENV{LLVM_HOME})
  set(LLVM_HOME "$ENV{LLVM_HOME}")
  set(LLVM_HOME "${LLVM_HOME}" CACHE PATH "Path to LLVM")
else()
  find_program(LLVM llc)
  if (NOT LLVM)
    message(FATAL_ERROR "LLVM_HOME not set, and could not find llc in "
                        "your PATH. ")
  endif()
  set(LLVM_HOME "" CACHE PATH "Path to LLVM")  
endif()
message(STATUS "Using LLVM_HOME: ${LLVM_HOME}")

### Find CUDA libs/tools
find_library(CUDA_LIB cuda PATHS "${CUDA_HOME}/lib64" /usr/local/cuda/lib64)
if(NOT CUDA_LIB)
  message(FATAL_ERROR "Unable to locate CUDA library/framework")
else()
  get_filename_component(CUDA_LIB_DIR ${CUDA_LIB} PATH)
  message(STATUS "CUDA lib path = ${CUDA_LIB_DIR}")
  link_directories(${CUDA_LIB_DIR})
endif()
find_library(CUDA_RT_LIB cudart PATHS "${CUDA_HOME}/lib64" /usr/local/cuda/lib64)
if(NOT CUDA_RT_LIB)
  message(FATAL_ERROR "Unable to locate CUDA RT library/framework")
else()
  get_filename_component(CUDA_RT_LIB_DIR ${CUDA_RT_LIB} PATH)
  message(STATUS "CUDA RT lib path = ${CUDA_RT_LIB_DIR}")
  link_directories(${CUDA_RT_LIB_DIR})
endif()

find_file(CUDA_H cuda.h PATHS "${CUDA_HOME}" "${CUDA_HOME}/include" /usr/local/cuda/include)
if(CUDA_H)
  get_filename_component(CUDA_INCLUDE_DIR ${CUDA_H} PATH)
  include_directories(${CUDA_INCLUDE_DIR})
else()
  message(FATAL_ERROR "Unable to locate cuda.h")
endif()
message(STATUS "Using cuda header: ${CUDA_H}")

find_program(NVCC nvcc PATHS "${CUDA_HOME}" "${CUDA_HOME}/bin")
if (NOT NVCC)
  message(FATAL_ERROR "Cannot find nvcc.  Please set CUDA_HOME to a CUDA Toolkit directory")
endif()
message(STATUS "Using nvcc: ${NVCC}")

### Include common headers
include_directories("${CMAKE_CURRENT_SOURCE_DIR}")

### Src
add_subdirectory(src)

