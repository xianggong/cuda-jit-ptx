target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v32:32:32-v64:64:64-v128:128:128-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

; Intrinsic to read X component of thread ID
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() readnone nounwind
; Intrinsic to read X component of block ID
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() readnone nounwind
; Intrinsic to read X component of block dim
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() readnone nounwind

define void @kernel(float addrspace(1)* %A,
                    float addrspace(1)* %B,
                    float addrspace(1)* %C,
                    i32 addrspace(1)* %TidX,
                    i32 addrspace(1)* %TidY,
                    i32 addrspace(1)* %TidZ,
                    i32 addrspace(1)* %NtidX,
                    i32 addrspace(1)* %NtidY,
                    i32 addrspace(1)* %NtidZ,
                    i32 addrspace(1)* %Laneid,
                    i32 addrspace(1)* %Warpid,
                    i32 addrspace(1)* %Nwarpid,
                    i32 addrspace(1)* %CtaidX,
                    i32 addrspace(1)* %CtaidY,
                    i32 addrspace(1)* %CtaidZ,
                    i32 addrspace(1)* %NctaidX,
                    i32 addrspace(1)* %NctaidY,
                    i32 addrspace(1)* %NctaidZ,
                    i32 addrspace(1)* %SMid,
                    i32 addrspace(1)* %Nsmid,
                    i32 addrspace(1)* %Gridid,
                    i32 addrspace(1)* %Clock) {
entry:
  ; What is my ID?
  %tid = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x() readnone nounwind
  %bid = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() readnone nounwind
  %bdim = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x() readnone nounwind

  %id_base = mul i32 %bid, %bdim
  %id = add i32 %id_base, %tid

  ; Compute pointers into A, B, and C
  %ptrA = getelementptr float addrspace(1)* %A, i32 %id
  %ptrB = getelementptr float addrspace(1)* %B, i32 %id
  %ptrC = getelementptr float addrspace(1)* %C, i32 %id

  ; And other pointers for special registers
  %ptrTidX = getelementptr i32 addrspace(1)* %TidX, i32 %id;
  %ptrTidY = getelementptr i32 addrspace(1)* %TidY, i32 %id;
  %ptrTidZ = getelementptr i32 addrspace(1)* %TidZ, i32 %id;
  %ptrNtidX = getelementptr i32 addrspace(1)* %NtidX, i32 %id;
  %ptrNtidY = getelementptr i32 addrspace(1)* %NtidY, i32 %id;
  %ptrNtidZ = getelementptr i32 addrspace(1)* %NtidZ, i32 %id;
  %ptrLaneid = getelementptr i32 addrspace(1)* %Laneid, i32 %id;
  %ptrWarpid = getelementptr i32 addrspace(1)* %Warpid, i32 %id;
  %ptrNwarpid = getelementptr i32 addrspace(1)* %Nwarpid, i32 %id;
  %ptrCtaidX = getelementptr i32 addrspace(1)* %CtaidX, i32 %id;
  %ptrCtaidY = getelementptr i32 addrspace(1)* %CtaidY, i32 %id;
  %ptrCtaidZ = getelementptr i32 addrspace(1)* %CtaidZ, i32 %id;
  %ptrNctaidX = getelementptr i32 addrspace(1)* %NctaidX, i32 %id;
  %ptrNctaidY = getelementptr i32 addrspace(1)* %NctaidY, i32 %id;
  %ptrNctaidZ = getelementptr i32 addrspace(1)* %NctaidZ, i32 %id;
  %ptrSMid = getelementptr i32 addrspace(1)* %SMid, i32 %id;
  %ptrNsmid = getelementptr i32 addrspace(1)* %Nsmid, i32 %id;
  %ptrGridid = getelementptr i32 addrspace(1)* %Gridid, i32 %id;
  %ptrClock = getelementptr i32 addrspace(1)* %Clock, i32 %id;

  ; Inline PTX to load SM ID
  %tidx = call i32 asm "mov.u32 $0, %tid.x;", "=r"()
  %tidy = call i32 asm "mov.u32 $0, %tid.y;", "=r"()
  %tidz = call i32 asm "mov.u32 $0, %tid.z;", "=r"()
  %ntidx = call i32 asm "mov.u32 $0, %ntid.x;", "=r"()
  %ntidy = call i32 asm "mov.u32 $0, %ntid.y;", "=r"()
  %ntidz = call i32 asm "mov.u32 $0, %ntid.z;", "=r"()
  %laneid = call i32 asm "mov.u32 $0, %laneid;", "=r"()
  %warpid = call i32 asm "mov.u32 $0, %warpid;", "=r"()
  %nwarpid = call i32 asm "mov.u32 $0, %nwarpid;", "=r"()
  %ctaidx = call i32 asm "mov.u32 $0, %ctaid.x;", "=r"()
  %ctaidy = call i32 asm "mov.u32 $0, %ctaid.y;", "=r"()
  %ctaidz = call i32 asm "mov.u32 $0, %ctaid.z;", "=r"()
  %nctaidx = call i32 asm "mov.u32 $0, %nctaid.x;", "=r"()
  %nctaidy = call i32 asm "mov.u32 $0, %nctaid.y;", "=r"()
  %nctaidz = call i32 asm "mov.u32 $0, %nctaid.z;", "=r"()
  %smid = call i32 asm "mov.u32 $0, %smid;", "=r"()
  %nsmid = call i32 asm "mov.u32 $0, %nsmid;", "=r"()
  %gridid = call i32 asm "mov.u32 $0, %gridid;", "=r"()
  %clock = call i32 asm "mov.u32 $0, %clock;", "=r"()

  ; Read A
  %valA = load float addrspace(1)* %ptrA, align 4

  ; Read B
  %valB = load float addrspace(1)* %ptrB, align 4

  ; Read C
  %valAPlusB = fadd float %valA, %valB

  ; Store back to C
  store float %valAPlusB, float addrspace(1)* %ptrC, align 4

  ; Store SM ID
  store i32 %tidx, i32 addrspace(1)* %ptrTidX, align 4
  store i32 %tidy, i32 addrspace(1)* %ptrTidY, align 4
  store i32 %tidz, i32 addrspace(1)* %ptrTidZ, align 4
  store i32 %ntidx, i32 addrspace(1)* %ptrNtidX, align 4
  store i32 %ntidy, i32 addrspace(1)* %ptrNtidY, align 4
  store i32 %ntidz, i32 addrspace(1)* %ptrNtidZ, align 4
  store i32 %laneid, i32 addrspace(1)* %ptrLaneid, align 4
  store i32 %warpid, i32 addrspace(1)* %ptrWarpid, align 4
  store i32 %nwarpid, i32 addrspace(1)* %ptrNwarpid, align 4
  store i32 %ctaidx, i32 addrspace(1)* %ptrCtaidX, align 4
  store i32 %ctaidy, i32 addrspace(1)* %ptrCtaidY, align 4
  store i32 %ctaidz, i32 addrspace(1)* %ptrCtaidZ, align 4
  store i32 %nctaidx, i32 addrspace(1)* %ptrNctaidX, align 4
  store i32 %nctaidy, i32 addrspace(1)* %ptrNctaidY, align 4
  store i32 %nctaidz, i32 addrspace(1)* %ptrNctaidZ, align 4
  store i32 %smid, i32 addrspace(1)* %ptrSMid, align 4
  store i32 %nsmid, i32 addrspace(1)* %ptrNsmid, align 4
  store i32 %gridid, i32 addrspace(1)* %ptrGridid, align 4
  store i32 %clock, i32 addrspace(1)* %ptrClock, align 4

  ret void
}

!nvvm.annotations = !{!0}
!0 = metadata !{void (float addrspace(1)*,
                      float addrspace(1)*,
                      float addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*)* @kernel, metadata !"kernel", i32 1}
