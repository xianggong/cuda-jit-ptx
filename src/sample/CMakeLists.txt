set ( EXE_NAME sample )
set ( SRC_FILES sample.cpp )

# Generate PTX from LLVM IR
add_custom_target(
	${EXE_NAME}_IR
	COMMAND "${CMAKE_COMMAND}" -E chdir
        "${CMAKE_CURRENT_SOURCE_DIR}" 
	llc -mcpu=sm_20 kernel.ll -o kernel.ptx
	COMMENT "Using llc to generate kernel ptx from LLVM IR"
	WORKING_DIRECTORY .
	VERBATIM
)

# Generate host program
add_executable(${EXE_NAME} ${SRC_FILES})
target_link_libraries(${EXE_NAME} cuda)
add_dependencies(${EXE_NAME} ${EXE_NAME}_IR)

# Move PTX file to binary directory
add_custom_command(
	TARGET ${EXE_NAME} POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E copy_if_different 
	${CMAKE_CURRENT_SOURCE_DIR}/kernel.ptx ./
	COMMAND ${CMAKE_COMMAND} -E remove 
	${CMAKE_CURRENT_SOURCE_DIR}/kernel.ptx
) 
