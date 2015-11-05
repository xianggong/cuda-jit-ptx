#!/bin/bash

# ------------------------- Global variables ------------------------
# Profiling file name
dataFileName=$(date +%H_%M_%S_%Y)
profDataFileName=profData_${dataFileName}
rawDataFileName=rawData_${dataFileName}

# Executable file name
execName=inst_sched_8

# ----------------------------- Checks -----------------------------
# Check number of parameters
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 maxStride maxAluDistance maxMemDistance sm_arch"
  exit 1
fi

# Read global variables
maxStride=$1
maxAluDistance=$2
maxMemDistance=$3
sm_arch=$4

# Check parameters
maxMemDistanceUpper=$(expr $maxAluDistance / 2)
if [ "$maxMemDistance" -gt "$maxMemDistanceUpper" ]; then
  echo "maxMemDistance too large, shrink to $maxMemDistanceUpper"
  maxMemDistance=$maxMemDistanceUpper
fi

# Helper function
checkTool () {
  if [ "$#" -ne 1 ]; then
    echo ": $0 toolName"
    exit 1
  fi
  tool=$1  
  command -v $tool >/dev/null 2>&1 || { echo >&2 \
  "Can't find $tool, aborting."; exit 1; }
}

# Check tools
checkTool "ptxas"
checkTool "cuobjdump"
checkTool "llc"

# --------------------------- Functions ----------------------------
# Generate PTX file
genPtx () {
  # Check number of args
  if [ "$#" -ne 2 ]; then
    echo ": $0 mcpu fileName"
    exit 1
  fi
  mcpu=$1
  fileName=$2
  out=$(llc -mcpu=${mcpu} ${fileName}.ll -o ${fileName}.ptx)

  # Check if error
  err=$(echo "$out" | grep -io "error")
  if [ -n "$err" ]; then 
    echo "-1"
    return 0
  fi
}

# Generate kernel object file
genObj () {
  # Check number of args
  if [ "$#" -ne 2 ]; then
    echo ": $0 arch fileName"
    exit 1
  fi
  arch=$1
  fileName=$2
  ptxas -arch=${arch} ${fileName}.ptx -o ${fileName}.o
}

# Generate kernel asm file
genAsm () {
  # Check number of args
  if [ "$#" -ne 1 ]; then
    echo ": $0 fileName"
    exit 1
  fi
  fileName=$1
  cuobjdump --dump-sass ${fileName}.o > ${fileName}.asm
}

# Generate kernel running files
genKernelRunFiles () {
  # Check number of args
  if [ "$#" -ne 3 ]; then
    echo ": $0 aluWindowSize memDistance arch"
    exit 1
  fi
  
  # Get params
  aluWindowSize=$1
  memDistance=$2
  arch=$3
  
  # Generate 3 .ll kernel files
  out=$(python gen_kernel.py ${aluWindowSize} ${memDistance})

  # Check if error
  err=$(echo "$out" | grep -io "error")
  if [ -n "$err" ]; then 
    echo "-1"
    return 0
  fi

  # And corresponding .ptx files
  local out=$(genPtx $arch kernel0_${aluWindowSize}_${memDistance})
  out+=$(genPtx $arch kernel1_${aluWindowSize}_${memDistance})
  out+=$(genPtx $arch kernel2_${aluWindowSize}_${memDistance})

  # Check if error
  err=$(echo "$out" | grep -io "error")
  if [ -n "$err" ]; then 
    echo "-1"
    return 0
  fi
  
  # return 
  echo "0"
}

# Generate kernel verification file
genKernelVerifyFiles () {
  # Check number of args
  if [ "$#" -ne 3 ]; then
    echo ": $0 aluWindowSize memDistance mcpu"
    exit 1
  fi
  
  # Get params
  aluWindowSize=$1
  memDistance=$2
  arch=$3

  # Gen 3 .o files
  genObj $arch kernel0_${aluWindowSize}_${memDistance}
  genObj $arch kernel1_${aluWindowSize}_${memDistance}
  genObj $arch kernel2_${aluWindowSize}_${memDistance}

  # And 3 .asm files
  genAsm kernel0_${aluWindowSize}_${memDistance}
  genAsm kernel1_${aluWindowSize}_${memDistance}
  genAsm kernel2_${aluWindowSize}_${memDistance}
}

# Run kernel
runKernel () {
  # Check number of args
  if [ "$#" -ne 7 ]; then
    echo ": $0 aluWindowSize memDistance arch dataCount scale stride blockSize"
    exit 1
  fi
  
  # Get params
  aluDist=$1
  memDist=$2
  arch=$3
  dataCount=$4
  scale=$5
  stride=$6
  blockSize=$7

  # Run and capture the raw profiling data
  namePostfix=${aluDist}_${memDist}
  k0Raw=$(./${execName} $dataCount $scale $stride $blockSize kernel0_${namePostfix}.ptx 2>&1) 
  k1Raw=$(./${execName} $dataCount $scale $stride $blockSize kernel1_${namePostfix}.ptx 2>&1) 
  k2Raw=$(./${execName} $dataCount $scale $stride $blockSize kernel2_${namePostfix}.ptx 2>&1) 

  # Check if any error
  k0Error=$(echo "$k0Raw" | grep -io "error")
  if [ -n "$k0Error" ]; then 
    echo "$k0Raw"
    return -1
  fi
  k1Error=$(echo "$k1Raw" | grep -io "error")
  if [ -n "$k1Error" ]; then 
    echo "$k1Raw"
    return -1
  fi
  k2Error=$(echo "$k2Raw" | grep -io "error")
  if [ -n "$k2Error" ]; then 
    echo "$k2Raw"
    return -1
  fi

  # Save raw data
  local rawFile=${rawDataFileName}_${aluDist}_${memDist}
  echo "$aluDist $memDist $dataCount $scale $stride" >> $rawFile
  echo "$k0Raw" >> $rawFile 
  echo "$k1Raw" >> $rawFile
  echo "$k2Raw" >> $rawFile

  # Some analysis
  k0=$(echo "$k0Raw" | grep "ms" | awk '{print $6}' 2>&1)
  k1=$(echo "$k1Raw" | grep "ms" | awk '{print $6}' 2>&1)
  k2=$(echo "$k2Raw" | grep "ms" | awk '{print $6}' 2>&1)

  # Calculate speedup
  k0Value=$(echo "$k0" | grep -o "[0-9]*[\.]?[0-9]*")
  k1Value=$(echo "$k1" | grep -o "[0-9]*[\.]?[0-9]*")
  k2Value=$(echo "$k2" | grep -o "[0-9]*[\.]?[0-9]*")
  speedup01=$(echo "scale=8; $k0Value/$k1Value*100" | bc)
  speedup02=$(echo "scale=8; $k0Value/$k2Value*100" | bc)
  echo "$aluDist $memDist $dataCount $scale $stride $k0 $k1 $k2 $speedup01% $speedup02%" >> \
       ${profDataFileName}_${aluDist}_${memDist}
}

# Run kernel with nvprof
runKernelNvprof () {
  # Check number of args
  if [ "$#" -ne 7 ]; then
    echo ": $0 aluWindowSize memDistance arch dataCount scale stride blockSize"
    exit 1
  fi
  
  # Get params
  aluDist=$1
  memDist=$2
  arch=$3
  dataCount=$4
  scale=$5
  stride=$6
  blockSize=$7

  # Run and capture the raw profiling data
  namePostfix=${aluDist}_${memDist}
  k0Raw=$(nvprof ./${execName} $dataCount $scale $stride $blockSize kernel0_${namePostfix}.ptx 2>&1) 
  k1Raw=$(nvprof ./${execName} $dataCount $scale $stride $blockSize kernel1_${namePostfix}.ptx 2>&1) 
  k2Raw=$(nvprof ./${execName} $dataCount $scale $stride $blockSize kernel2_${namePostfix}.ptx 2>&1) 

  # Check if any error
  k0Error=$(echo "$k0Raw" | grep -io "error")
  if [ -n "$k0Error" ]; then 
    echo "$k0Raw"
    return -1
  fi
  k1Error=$(echo "$k1Raw" | grep -io "error")
  if [ -n "$k1Error" ]; then 
    echo "$k1Raw"
    return -1
  fi
  k2Error=$(echo "$k2Raw" | grep -io "error")
  if [ -n "$k2Error" ]; then 
    echo "$k2Raw"
    return -1
  fi

  # Save raw data
  echo "$aluDist $memDist $dataCount $scale $stride" >> $rawDataFileName
  echo "$k0Raw" >> $rawDataFileName
  echo "$k1Raw" >> $rawDataFileName
  echo "$k2Raw" >> $rawDataFileName

  # Some analysis
  k0=$(echo "$k0Raw" | grep "  kernel" | awk '{print $2}' 2>&1)
  k1=$(echo "$k1Raw" | grep "  kernel" | awk '{print $2}' 2>&1)
  k2=$(echo "$k2Raw" | grep "  kernel" | awk '{print $2}' 2>&1)

  # Calculate speedup
  k0Value=$(echo "$k0" | egrep -o "[1-9][0-9]*\.?[0-9]*")
  k1Value=$(echo "$k1" | egrep -o "[1-9][0-9]*\.?[0-9]*")
  k2Value=$(echo "$k2" | egrep -o "[1-9][0-9]*\.?[0-9]*")
  if [ -n "$k0Value"] && [ -n "$k1Value"] && [ -n "$k2Value"]
    speedup01=$(echo "scale=8; $k0Value/$k1Value*100" | bc)
    speedup02=$(echo "scale=8; $k0Value/$k2Value*100" | bc)
    echo "$aluDist $memDist $dataCount $scale $stride $k0 $k1 $k2 $speedup01% $speedup02%" >> \
         ${aluDist}_${memDist}_$dataFileName
  else
    echo "$aluDist $memDist $dataCount $scale $stride $k0 $k1 $k2 err% err%" >> \
         ${aluDist}_${memDist}_$dataFileName
  fi
}

# Generate, run and profile
run() {
  for((aluDist=1;aluDist<=$maxAluDistance;aluDist+=1))
  do
    memDistMaxLocal=$(expr $aluDist / 2)
    memDistMax=$([ "$maxMemDistance" -le "$memDistMaxLocal" ] && echo "$maxMemDistance" || echo "$memDistMaxLocal")
    for((memDist=0;memDist<=$memDistMax;memDist+=1))
    do
      # Generate .ll and .ptx
      out=$(genKernelRunFiles $aluDist $memDist $sm_arch)
      if [ "$out" == "-1" ]; then 
        echo "Error generating .ll and .ptx : aluDist = $aluDist, memDist = $memDist"
      else
        # Generate .o and .asm 
        out=$(genKernelVerifyFiles $aluDist $memDist $sm_arch)
        if [ "$out" == "-1" ]; then 
          echo "Error generating .o and .asm : aluDist = $aluDist, memDist = $memDist"
	else
          for ((blockSize=32;blockSize<=1024;blockSize*=2))
          do
            maxScale=$((1024*32760/${blockSize}))
            for ((scale=1;scale<$maxScale;scale*=2))
            do
              dataCount=$(($blockSize*15))
              for((stride=1;stride<=$maxStride;stride+=1))
              do
                runKernel $aluDist $memDist $sm_arch $dataCount $scale $stride $blockSize
              done
            done
          done
         fi
      fi
   done 
  done
}

####### Main

run

