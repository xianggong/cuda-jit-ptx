It contains several micro benchmarks based on vector add

0. sample 
  Vector add benchmark from Nvidia NVVM github repo
1. inst_sched_0 
  Vector add, kernel 0, Hyper-Q implementation
2. inst_sched_1
  Vector add, kernel 1, Hyper-Q implementation
3. inst_sched_2
  Vector add, kernel 2, Hyper-Q implementation
4. inst_sched_3
  Vector add, 3 kernels included. 1 command queue,
  kernels take different branch path based on SM id.
5. inst_sched_4
  Vector add, 3 kernels included. Enhanced version
  in terms of data size
