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
                    i32 addrspace(1)* %SMid,
                    i32 addrspace(1)* %LoopCount) {
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
  %ptrSMid = getelementptr i32 addrspace(1)* %SMid, i32 %id
  %ptrLoopCount = getelementptr i32 addrspace(1)* %LoopCount, i32 0 

  ; Loop count
  %loops = load i32 addrspace(1)* %ptrLoopCount, align 4

  ; Inline PTX to load SM ID
  %smid = call i32 asm "mov.u32 $0, %smid;", "=r"()

  ; SM ID % 2
  %smidrem2 = urem i32 %smid, 2

  ; Branch 
  %cond = icmp eq i32 %smidrem2, 0
  br i1 %cond, label %k0.for.cond, label %k1.for.cond 

k0.for.cond:
  %k0.i = phi i32 [0, %entry], [%k0.inc, %k0.for.inc]

  %k0.a = phi float [0.0, %entry], [%k0_addA_8, %k0.for.inc]
  %k0.b = phi float [0.0, %entry], [%k0_addB_8, %k0.for.inc]
  %k0.c = phi float [0.0, %entry], [%k0_addC_8, %k0.for.inc]

  %k0.cond = icmp slt i32 %k0.i, %loops 
  br i1 %k0.cond, label %k0.for.body, label %k0.for.end

k0.for.body:
  ; Read A
  %k0_valA = load float addrspace(1)* %ptrA, align 4

  ; Read B
  %k0_valB = load float addrspace(1)* %ptrB, align 4

  ; Read C
  %k0_valC = load float addrspace(1)* %ptrC, align 4

  ; ALU on A
  %k0_valA_0 = fdiv float %k0_valA, 1.0
  %k0_valA_1 = fdiv float %k0_valA, 2.0
  %k0_valA_2 = fdiv float %k0_valA, 3.0
  %k0_valA_3 = fdiv float %k0_valA, 4.0
  %k0_valA_4 = fdiv float %k0_valA, 5.0
  %k0_valA_5 = fdiv float %k0_valA, 6.0
  %k0_valA_6 = fdiv float %k0_valA, 7.0
  %k0_valA_7 = fdiv float %k0_valA, 8.0
  %k0_valA_8 = fdiv float %k0_valA, 9.0
  %k0_valA_9 = fdiv float %k0_valA, 10.0

  %k0_addA_0 = fadd float %k0_valA_0, %k0_valA_1
  %k0_addA_1 = fadd float %k0_valA_2, %k0_valA_3
  %k0_addA_2 = fadd float %k0_valA_4, %k0_valA_5
  %k0_addA_3 = fadd float %k0_valA_6, %k0_valA_7
  %k0_addA_4 = fadd float %k0_valA_8, %k0_valA_9

  %k0_addA_5 = fadd float %k0_addA_0, %k0_addA_1
  %k0_addA_6 = fadd float %k0_addA_2, %k0_addA_3
  %k0_addA_7 = fadd float %k0_addA_5, %k0_addA_6
  %k0_addA_8 = fadd float %k0_addA_4, %k0_addA_7
  
  ; ALU on B
  %k0_valB_0 = fdiv float %k0_valB, 1.0
  %k0_valB_1 = fdiv float %k0_valB, 2.0
  %k0_valB_2 = fdiv float %k0_valB, 3.0
  %k0_valB_3 = fdiv float %k0_valB, 4.0
  %k0_valB_4 = fdiv float %k0_valB, 5.0
  %k0_valB_5 = fdiv float %k0_valB, 6.0
  %k0_valB_6 = fdiv float %k0_valB, 7.0
  %k0_valB_7 = fdiv float %k0_valB, 8.0
  %k0_valB_8 = fdiv float %k0_valB, 9.0
  %k0_valB_9 = fdiv float %k0_valB, 10.0

  %k0_addB_0 = fadd float %k0_valB_0, %k0_valB_1
  %k0_addB_1 = fadd float %k0_valB_2, %k0_valB_3
  %k0_addB_2 = fadd float %k0_valB_4, %k0_valB_5
  %k0_addB_3 = fadd float %k0_valB_6, %k0_valB_7
  %k0_addB_4 = fadd float %k0_valB_8, %k0_valB_9

  %k0_addB_5 = fadd float %k0_addB_0, %k0_addB_1
  %k0_addB_6 = fadd float %k0_addB_2, %k0_addB_3
  %k0_addB_7 = fadd float %k0_addB_5, %k0_addB_6
  %k0_addB_8 = fadd float %k0_addB_4, %k0_addB_7

  ; ALU on C
  %k0_valC_0 = fdiv float %k0_valC, 1.0
  %k0_valC_1 = fdiv float %k0_valC, 2.0
  %k0_valC_2 = fdiv float %k0_valC, 3.0
  %k0_valC_3 = fdiv float %k0_valC, 4.0
  %k0_valC_4 = fdiv float %k0_valC, 5.0
  %k0_valC_5 = fdiv float %k0_valC, 6.0
  %k0_valC_6 = fdiv float %k0_valC, 7.0
  %k0_valC_7 = fdiv float %k0_valC, 8.0
  %k0_valC_8 = fdiv float %k0_valC, 9.0
  %k0_valC_9 = fdiv float %k0_valC, 10.0

  %k0_addC_0 = fadd float %k0_valC_0, %k0_valC_1
  %k0_addC_1 = fadd float %k0_valC_2, %k0_valC_3
  %k0_addC_2 = fadd float %k0_valC_4, %k0_valC_5
  %k0_addC_3 = fadd float %k0_valC_6, %k0_valC_7
  %k0_addC_4 = fadd float %k0_valC_8, %k0_valC_9

  %k0_addC_5 = fadd float %k0_addC_0, %k0_addC_1
  %k0_addC_6 = fadd float %k0_addC_2, %k0_addC_3
  %k0_addC_7 = fadd float %k0_addC_5, %k0_addC_6
  %k0_addC_8 = fadd float %k0_addC_4, %k0_addC_7

  br label %k0.for.inc

k0.for.inc:
  %k0.inc = add i32 %k0.i, 1
  br label %k0.for.cond

k0.for.end:
  br label %exit

k1.for.cond:
  %k1.i = phi i32 [0, %entry], [%k1.inc, %k1.for.inc]

  %k1.a = phi float [0.0, %entry], [%k1_addA_8, %k1.for.inc]
  %k1.b = phi float [0.0, %entry], [%k1_addB_8, %k1.for.inc]
  %k1.c = phi float [0.0, %entry], [%k1_addC_8, %k1.for.inc]
 
  %k1.cond = icmp slt i32 %k1.i, %loops
  br i1 %k1.cond, label %k1.for.body, label %k1.for.end

k1.for.body:
  ; Read A
  %k1_valA = load float addrspace(1)* %ptrA, align 4

  ; Read B
  %k1_valB = load float addrspace(1)* %ptrB, align 4

  ; Read C
  %k1_valC = load float addrspace(1)* %ptrC, align 4

  ; ALU on A
  %k1_valA_0 = fdiv float %k1_valA, 1.0
  %k1_valA_1 = fdiv float %k1_valA, 2.0
  %k1_valA_2 = fdiv float %k1_valA, 3.0
  %k1_valA_3 = fdiv float %k1_valA, 4.0
  %k1_valA_4 = fdiv float %k1_valA, 5.0
  %k1_valA_5 = fdiv float %k1_valA, 6.0
  %k1_valA_6 = fdiv float %k1_valA, 7.0
  %k1_valA_7 = fdiv float %k1_valA, 8.0
  %k1_valA_8 = fdiv float %k1_valA, 9.0
  %k1_valA_9 = fdiv float %k1_valA, 10.0

  %k1_addA_0 = fadd float %k1_valA_0, %k1_valA_1
  %k1_addA_1 = fadd float %k1_valA_2, %k1_valA_3
  %k1_addA_2 = fadd float %k1_valA_4, %k1_valA_5
  %k1_addA_3 = fadd float %k1_valA_6, %k1_valA_7
  %k1_addA_4 = fadd float %k1_valA_8, %k1_valA_9

  %k1_addA_5 = fadd float %k1_addA_0, %k1_addA_1
  %k1_addA_6 = fadd float %k1_addA_2, %k1_addA_3
  %k1_addA_7 = fadd float %k1_addA_5, %k1_addA_6
  %k1_addA_8 = fadd float %k1_addA_4, %k1_addA_7
  
  ; ALU on B
  %k1_valB_0 = fdiv float %k1_valB, 1.0
  %k1_valB_1 = fdiv float %k1_valB, 2.0
  %k1_valB_2 = fdiv float %k1_valB, 3.0
  %k1_valB_3 = fdiv float %k1_valB, 4.0
  %k1_valB_4 = fdiv float %k1_valB, 5.0
  %k1_valB_5 = fdiv float %k1_valB, 6.0
  %k1_valB_6 = fdiv float %k1_valB, 7.0
  %k1_valB_7 = fdiv float %k1_valB, 8.0
  %k1_valB_8 = fdiv float %k1_valB, 9.0
  %k1_valB_9 = fdiv float %k1_valB, 10.0

  %k1_addB_0 = fadd float %k1_valB_0, %k1_valB_1
  %k1_addB_1 = fadd float %k1_valB_2, %k1_valB_3
  %k1_addB_2 = fadd float %k1_valB_4, %k1_valB_5
  %k1_addB_3 = fadd float %k1_valB_6, %k1_valB_7
  %k1_addB_4 = fadd float %k1_valB_8, %k1_valB_9

  %k1_addB_5 = fadd float %k1_addB_0, %k1_addB_1
  %k1_addB_6 = fadd float %k1_addB_2, %k1_addB_3
  %k1_addB_7 = fadd float %k1_addB_5, %k1_addB_6
  %k1_addB_8 = fadd float %k1_addB_4, %k1_addB_7

  ; ALU on C
  %k1_valC_0 = fdiv float %k1_valC, 1.0
  %k1_valC_1 = fdiv float %k1_valC, 2.0
  %k1_valC_2 = fdiv float %k1_valC, 3.0
  %k1_valC_3 = fdiv float %k1_valC, 4.0
  %k1_valC_4 = fdiv float %k1_valC, 5.0
  %k1_valC_5 = fdiv float %k1_valC, 6.0
  %k1_valC_6 = fdiv float %k1_valC, 7.0
  %k1_valC_7 = fdiv float %k1_valC, 8.0
  %k1_valC_8 = fdiv float %k1_valC, 9.0
  %k1_valC_9 = fdiv float %k1_valC, 10.0

  %k1_addC_0 = fadd float %k1_valC_0, %k1_valC_1
  %k1_addC_1 = fadd float %k1_valC_2, %k1_valC_3
  %k1_addC_2 = fadd float %k1_valC_4, %k1_valC_5
  %k1_addC_3 = fadd float %k1_valC_6, %k1_valC_7
  %k1_addC_4 = fadd float %k1_valC_8, %k1_valC_9

  %k1_addC_5 = fadd float %k1_addC_0, %k1_addC_1
  %k1_addC_6 = fadd float %k1_addC_2, %k1_addC_3
  %k1_addC_7 = fadd float %k1_addC_5, %k1_addC_6
  %k1_addC_8 = fadd float %k1_addC_4, %k1_addC_7

  br label %k1.for.inc

k1.for.inc:
  %k1.inc = add i32 %k1.i, 1
  br label %k1.for.cond

k1.for.end:
  br label %exit
 
exit:
  %addA_8 = phi float [%k0.a, %k0.for.end], [%k1.a, %k1.for.end]
  %addB_8 = phi float [%k0.b, %k0.for.end], [%k1.b, %k1.for.end]
  %addC_8 = phi float [%k0.c, %k0.for.end], [%k1.c, %k1.for.end]

  ; Compute A + B
  %addAB = fadd float %addA_8, %addB_8
 
  ; Compute A + B + C
  %addABC = fadd float %addC_8, %addAB

  ; Store back to C
  store float %addABC, float addrspace(1)* %ptrC, align 4

  ; Store SM ID
  store i32 %smid, i32 addrspace(1)* %ptrSMid, align 4

  ret void
}

!nvvm.annotations = !{!0}
!0 = metadata !{void (float addrspace(1)*,
                      float addrspace(1)*,
                      float addrspace(1)*,
                      i32 addrspace(1)*,
                      i32 addrspace(1)*)* @kernel, metadata !"kernel", i32 1}
