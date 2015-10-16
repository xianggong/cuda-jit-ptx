  ; Read BUFNAME
  %kINDEX.ptrBUFNAME = getelementptr float addrspace(1)* %BUFNAME, i32 %kINDEX.i
  %kINDEX.valBUFNAME = load float addrspace(1)* %kINDEX.ptrBUFNAME, align 4

