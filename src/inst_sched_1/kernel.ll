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
                    float addrspace(1)* %C) {
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

  ; Read A
  %valA = load float addrspace(1)* %ptrA, align 4

  ; Read B
  %valB = load float addrspace(1)* %ptrB, align 4

  ; Read C
  %valC = load float addrspace(1)* %ptrC, align 4

  ; ALU on A
  %valA_0 = fmul float %valA, 1.0
  %valA_1 = fmul float %valA, 2.0
  %valA_2 = fmul float %valA, 3.0
  %valA_3 = fmul float %valA, 4.0
  %valA_4 = fmul float %valA, 5.0
  %valA_5 = fmul float %valA, 6.0
  %valA_6 = fmul float %valA, 7.0
  %valA_7 = fmul float %valA, 8.0
  %valA_8 = fmul float %valA, 9.0
  %valA_9 = fmul float %valA, 10.0

  %addA_0 = fadd float %valA_0, %valA_1
  %addA_1 = fadd float %valA_2, %valA_3
  %addA_2 = fadd float %valA_4, %valA_5
  %addA_3 = fadd float %valA_6, %valA_7
  %addA_4 = fadd float %valA_8, %valA_9

  %addA_5 = fadd float %addA_0, %addA_1
  %addA_6 = fadd float %addA_2, %addA_3
  %addA_7 = fadd float %addA_5, %addA_6
  %addA_8 = fadd float %addA_4, %addA_7
  
  ; ALU on B
  %valB_0 = fmul float %valB, 1.0
  %valB_1 = fmul float %valB, 2.0
  %valB_2 = fmul float %valB, 3.0
  %valB_3 = fmul float %valB, 4.0
  %valB_4 = fmul float %valB, 5.0
  %valB_5 = fmul float %valB, 6.0
  %valB_6 = fmul float %valB, 7.0
  %valB_7 = fmul float %valB, 8.0
  %valB_8 = fmul float %valB, 9.0
  %valB_9 = fmul float %valB, 10.0

  %addB_0 = fadd float %valB_0, %valB_1
  %addB_1 = fadd float %valB_2, %valB_3
  %addB_2 = fadd float %valB_4, %valB_5
  %addB_3 = fadd float %valB_6, %valB_7
  %addB_4 = fadd float %valB_8, %valB_9

  %addB_5 = fadd float %addB_0, %addB_1
  %addB_6 = fadd float %addB_2, %addB_3
  %addB_7 = fadd float %addB_5, %addB_6
  %addB_8 = fadd float %addB_4, %addB_7

  ; ALU on C
  %valC_0 = fmul float %valC, 1.0
  %valC_1 = fmul float %valC, 2.0
  %valC_2 = fmul float %valC, 3.0
  %valC_3 = fmul float %valC, 4.0
  %valC_4 = fmul float %valC, 5.0
  %valC_5 = fmul float %valC, 6.0
  %valC_6 = fmul float %valC, 7.0
  %valC_7 = fmul float %valC, 8.0
  %valC_8 = fmul float %valC, 9.0
  %valC_9 = fmul float %valC, 10.0

  %addC_0 = fadd float %valC_0, %valC_1
  %addC_1 = fadd float %valC_2, %valC_3
  %addC_2 = fadd float %valC_4, %valC_5
  %addC_3 = fadd float %valC_6, %valC_7
  %addC_4 = fadd float %valC_8, %valC_9

  %addC_5 = fadd float %addC_0, %addC_1
  %addC_6 = fadd float %addC_2, %addC_3
  %addC_7 = fadd float %addC_5, %addC_6
  %addC_8 = fadd float %addC_4, %addC_7

  ; Compute A + B
  %addAB = fadd float %addA_8, %addB_8
 
  ; Compute A + B + C
  %addABC = fadd float %addC_8, %addAB

  ; Store back to C
  store float %addABC, float addrspace(1)* %ptrC, align 4

  ret void
}

!nvvm.annotations = !{!0}
!0 = metadata !{void (float addrspace(1)*,
                      float addrspace(1)*,
                      float addrspace(1)*)* @kernel, metadata !"kernel", i32 1}
