#!/bin/bash

fileName=$(date +%H_%M_%S_%Y)

echo "$fileName"
for ((blockSize=32;blockSize<=1024;blockSize*=2))
do
  maxScale=$((1024*32760/${blockSize}))
  echo "$scale" >> ${fileName}.txt
# echo "$maxScale"
  for ((scale=1;scale<${maxScale};scale*=2))
  do
# echo "scale = $scale"
  dataCount=$(($blockSize*15))
# echo "dataCount = $dataCount"
# echo "blockSize = $blockSize"
  for((offset=0;offset<=32;offset+=1))
    do
    k0=$(nvprof ./inst_sched_7 $dataCount $scale $offset $blockSize kernel0.ptx 2>&1 | grep '  kernel' | awk '{print $2}' 2>&1)
    k1=$(nvprof ./inst_sched_7 $dataCount $scale $offset $blockSize kernel1.ptx 2>&1 | grep '  kernel' | awk '{print $2}' 2>&1)
    k2=$(nvprof ./inst_sched_7 $dataCount $scale $offset $blockSize kernel2.ptx 2>&1 | grep '  kernel' | awk '{print $2}' 2>&1)
#  echo "k0/1/2 $k0 $k1 $k2"
    k0Value=$(echo $k0 | grep -o "[0-9]*\.[0-9]*")
    k1Value=$(echo $k1 | grep -o "[0-9]*\.[0-9]*")
    k2Value=$(echo $k2 | grep -o "[0-9]*\.[0-9]*")
# echo "scale=10; $k0Value/$k1Value*100"
# echo "scale=10; $k0Value/$k2Value*100"
    speedup01=$(echo "scale=10; $k0Value/$k1Value*100" | bc)
    speedup02=$(echo "scale=10; $k0Value/$k2Value*100" | bc)
    echo "$dataCount $scale $offset $k0 $k1 $k2 $speedup01% $speedup02%" >> ${fileName}.txt
    done
  done
done

