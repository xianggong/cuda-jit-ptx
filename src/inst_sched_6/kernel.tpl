target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v32:32:32-v64:64:64-v128:128:128-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

; Intrinsic to read X component of thread ID
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() readnone nounwind
; Intrinsic to read X component of block ID
declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() readnone nounwind
; Intrinsic to read X component of block dim
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() readnone nounwind
; Intrinsic to read X component of grid dim
declare i32 @llvm.nvvm.read.ptx.sreg.nctaid.x() readnone nounwind

define void @kernel(float addrspace(1)* %A,
                    float addrspace(1)* %B,
                    float addrspace(1)* %C,
                    i32 addrspace(1)* %SMid,
                    i32 addrspace(1)* %NumElems) {
entry:
  ; What is my ID?
  %tid = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x() readnone nounwind
  %bid = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() readnone nounwind
  %bdim = tail call i32 @llvm.nvvm.read.ptx.sreg.ntid.x() readnone nounwind
  %gdim = tail call i32 @llvm.nvvm.read.ptx.sreg.nctaid.x() readnone nounwind

  %id_base = mul i32 %bid, %bdim
  %id = add i32 %id_base, %tid
  %gridStride = mul i32 %bdim, %gdim

  ; Other pointers
  %ptrNumElems = getelementptr i32 addrspace(1)* %NumElems, i32 0 

  ; Get num of elements
  %numElems = load i32 addrspace(1)* %ptrNumElems, align 4

  ; Inline PTX to load SM ID
  %smid = call i32 asm "mov.u32 $0, %smid;", "=r"()

  ; SM ID % 2
  %smidrem2 = urem i32 %smid, 2

  ; Branch 
  %cond = icmp eq i32 %smidrem2, 0
  br i1 %cond, label %k0.for.cond, label %k1.for.cond 

k0.for.cond:
  ; index = id; index < numElems; index += gridStride
  %k0.i = phi i32 [%id, %entry], [%k0.inc, %k0.for.inc]

  %k0.cond = icmp slt i32 %k0.i, %numElems
  br i1 %k0.cond, label %k0.for.body, label %k0.for.end

k0.for.body:
  ; Autogen begin
K0_AUTOGEN
  ; Autogen end
  
  ; C = alu(A) + alu(B) + alu(C)
  %k0.addAB = fadd float %k0.alu.A.last, %k0.alu.B.last
  %k0.addABC = fadd float %k0.addAB, %k0.alu.C.last

  ; Store back to C
  store float %k0.addABC, float addrspace(1)* %k0.ptrC, align 4

  ; Store SM ID
  %k0_ptrSMid = getelementptr i32 addrspace(1)* %SMid, i32 %k0.i
  store i32 %smid, i32 addrspace(1)* %k0_ptrSMid, align 4

  br label %k0.for.inc

k0.for.inc:
  %k0.inc = add i32 %k0.i, %gridStride
  br label %k0.for.cond

k0.for.end:
  ret void

k1.for.cond:
  ; index = id; index < numElems; index += gridStride
  %k1.i = phi i32 [%id, %entry], [%k1.inc, %k1.for.inc]

  %k1.cond = icmp slt i32 %k1.i, %numElems
  br i1 %k1.cond, label %k1.for.body, label %k1.for.end

k1.for.body:
  ; Autogen begin
K1_AUTOGEN
  ; Autogen end

  ; C = alu(A) + alu(B) + alu(C)
  %k1.addAB = fadd float %k1.alu.A.last, %k1.alu.B.last
  %k1.addABC = fadd float %k1.addAB, %k1.alu.C.last

  ; Store back to C
  store float %k1.addABC, float addrspace(1)* %k1.ptrC, align 4

  ; Store SM ID
  %k1_ptrSMid = getelementptr i32 addrspace(1)* %SMid, i32 %k1.i
  store i32 %smid, i32 addrspace(1)* %k1_ptrSMid, align 4

  br label %k1.for.inc

k1.for.inc:
  %k1.inc = add i32 %k1.i, %gridStride
  br label %k1.for.cond

k1.for.end:
  ret void 
}

!nvvm.annotations = !{!0}
!0 = metadata !{void (float addrspace(1)*,
                      float addrspace(1)*,
                      float addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*)* @kernel, metadata !"kernel", i32 1}
