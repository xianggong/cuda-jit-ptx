set ( EXE_NAME sample )
set ( SRC_FILES sample.cpp )

# Generate PTX from LLVM IR
add_custom_command(
	OUTPUT kernel.ptx
	COMMAND llc -mcpu=sm_20 kernel.ll -o kernel.ptx
	DEPENDS kernel.ll
	COMMENT "Using llc to generate kernel ptx from LLVM IR"
	WORKING_DIRECTORY ""
	VERBATIM
)
file(COPY kernel.ptx DESTINATION .)

# Generate host program
add_executable(${EXE_NAME} ${SRC_FILES})
target_link_libraries(${EXE_NAME} cuda)
