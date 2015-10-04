cmake_minimum_required(VERSION 2.8)

project(cuda-jit-ptx)


if (DEFINED ENV{CUDA_HOME})
  set(CUDA_HOME "$ENV{CUDA_HOME}")
  set(CUDA_HOME "$ENV{CUDA_HOME}" CACHE PATH "Path to CUDA Toolkit.")
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
endif()

message(STATUS "Using CUDA_HOME: ${CUDA_HOME}")

# LLVM
if(DEFINED ENV{LLVM_HOME})
  set(LLVM_HOME "$ENV{LLVM_HOME}")
  set(LLVM_HOME "${LLVM_HOME}" CACHE PATH "Path to LLVM 3.2.")
else()
  set(LLVM_HOME "" CACHE PATH "Path to LLVM 3.2.")  
endif()
message(STATUS "Using LLVM_HOME: ${LLVM_HOME}")

### Find CUDA libs/tools
find_library(CUDA_LIB cuda ${CUDA_LIB_SEARCH_PATH})
if(NOT CUDA_LIB)
  message(FATAL_ERROR "Unable to locate CUDA library/framework")
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


### Find LLVM
# LLVM is a bit tricky if we don't assume a CMake-based build
find_file(ADDLLVM_CMAKE AddLLVM.cmake PATHS "${LLVM_HOME}/share/llvm/cmake")
if(ADDLLVM_CMAKE)
  list(APPEND CMAKE_MODULE_PATH "${LLVM_HOME}/share/llvm/cmake")
  include(AddLLVM)
  include("${LLVM_HOME}/share/llvm/cmake/LLVMConfig.cmake")
  include(HandleLLVMOptions)
  include_directories("${LLVM_HOME}/include")
  link_directories("${LLVM_HOME}/lib")
  if (NOT LLVM_VERSION_MAJOR STREQUAL "3" OR NOT LLVM_VERSION_MINOR STREQUAL "2")
    message(STATUS "LLVM found, but version 3.2 is required.")
    message(STATUS "cuda-c-linking sample will not be built!")
  else()
    set(HAVE_LLVM YES)
    message(STATUS "Using LLVM install from ${LLVM_HOME}")
  endif()
else()
  message(STATUS "CMake-based LLVM install could not be found.")
  message(STATUS "cuda-c-linking sample will not be built!")
endif()


### Include common headers
include_directories("${CMAKE_CURRENT_SOURCE_DIR}")

### Samples
add_subdirectory(src)
