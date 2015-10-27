#!/bin/bash

# Profiling file name
fileName=$(date +%H_%M_%S_%Y)

# Executable file name
execName=inst_sched_8

# Read global variables
maxOffset=$1
maxAluDistance=$2
maxMemDistance=$3

# Check number of parameters
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 maxOffset maxAluDistance maxMemDistance"
  exit 1
fi

# Generate files
genFile () {
  for((aluDist=1;aluDist<=$maxAluDistance;aluDist+=1))
  do
    memDistMax=$([${maxMemDistance} -le ${aluDist}] && echo "$maxMemDistance" || echo "$aluDist")
    echo "max $memDistMax"
    for((memDist=1;memDist<=${memDistMax};memDist+=1))
    do
      # Generate ll kernels
      python gen_kernel.py $aluDist $memDist
      # Generate ptx kernels
      llc -mcpu=sm_20 kernel0_${aluDist}_${memDist}.ll -o kernel0_${aluDist}_${memDist}.ptx
      llc -mcpu=sm_20 kernel1_${aluDist}_${memDist}.ll -o kernel1_${aluDist}_${memDist}.ptx
      llc -mcpu=sm_20 kernel2_${aluDist}_${memDist}.ll -o kernel2_${aluDist}_${memDist}.ptx
      # Generate kernel objects
      ptxas -arch=sm_20 kernel0_${aluDist}_${memDist}.ptx -o kernel0_${aluDist}_${memDist}.o
      ptxas -arch=sm_20 kernel1_${aluDist}_${memDist}.ptx -o kernel1_${aluDist}_${memDist}.o
      ptxas -arch=sm_20 kernel2_${aluDist}_${memDist}.ptx -o kernel2_${aluDist}_${memDist}.o
      # Generate asm kernels
      cuobjdump --dump-sass kernel0_${aluDist}_${memDist}.o > kernel0_${aluDist}_${memDist}.asm
      cuobjdump --dump-sass kernel1_${aluDist}_${memDist}.o > kernel1_${aluDist}_${memDist}.asm
      cuobjdump --dump-sass kernel2_${aluDist}_${memDist}.o > kernel2_${aluDist}_${memDist}.asm
    done
  done
}

# Profiling
profile () {
  aluDist=$1
  memDist=$2
  echo "profile $aluDist $memDist"
  for ((blockSize=32;blockSize<=1024;blockSize*=2))
  do
    maxScale=$((1024*32760/${blockSize}))
    echo "$scale" >> ${fileName}.txt
#   echo "$maxScale"
    for ((scale=1;scale<${maxScale};scale*=2))
    do
#     echo "scale = $scale"
      dataCount=$(($blockSize*15))
#     echo "dataCount = $dataCount"
#     echo "blockSize = $blockSize"
      for((offset=0;offset<=$maxOffset;offset+=1))
      do
        k0=$(nvprof ./${execName} $dataCount $scale $offset $blockSize kernel0_${aluDist}_${memDist}.ptx 2>&1 | grep '  kernel' | awk '{print $2}' 2>&1)
        k1=$(nvprof ./${execName} $dataCount $scale $offset $blockSize kernel1_${aluDist}_${memDist}.ptx 2>&1 | grep '  kernel' | awk '{print $2}' 2>&1)
        k2=$(nvprof ./${execName} $dataCount $scale $offset $blockSize kernel2_${aluDist}_${memDist}.ptx 2>&1 | grep '  kernel' | awk '{print $2}' 2>&1)
#  echo "k0/1/2 $k0 $k1 $k2"
    k0Value=$(echo $k0 | grep -o "[0-9]*\.[0-9]*")
    k1Value=$(echo $k1 | grep -o "[0-9]*\.[0-9]*")
    k2Value=$(echo $k2 | grep -o "[0-9]*\.[0-9]*")
# echo "scale=10; $k0Value/$k1Value*100"
# echo "scale=10; $k0Value/$k2Value*100"
    speedup01=$(echo "scale=10; $k0Value/$k1Value*100" | bc)
    speedup02=$(echo "scale=10; $k0Value/$k2Value*100" | bc)
    echo "$aluDist $memDist $dataCount $scale $offset $k0 $k1 $k2 $speedup01% $speedup02%" >> ${fileName}.txt
    done
  done
done
}

####### Main

genFile

for((aluDist=1;aluDist<=$maxAluDistance;aluDist+=1))
do
  for((memDist=$aluDist;memDist<=$maxMemDistance;memDist+=1))
  do
    profile $aluDist $memDist
  done
done

