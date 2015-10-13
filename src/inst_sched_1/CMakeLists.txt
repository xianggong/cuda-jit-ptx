set ( EXE_NAME inst_sched_1 )
set ( SRC_FILES inst_sched_1.cpp )
set ( EXTRA_CLEAN_FILES kernel.ptx kernel.o kernel.asm )

# Extra files for make clean. Dont forget "", otherwise won't work
set_directory_properties (
	PROPERTIES
	ADDITIONAL_MAKE_CLEAN_FILES "${EXTRA_CLEAN_FILES}"
)

# Generate host program
add_executable(${EXE_NAME} ${SRC_FILES})
target_link_libraries(${EXE_NAME} cuda)

# Generate PTX file to binary directory
add_custom_command(
	TARGET ${EXE_NAME} POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	llc -mcpu=sm_20 ${CMAKE_CURRENT_SOURCE_DIR}/kernel.ll 
        -o kernel.ptx
	COMMENT "Generating kernel PTX files..."
)

# Generate OBJ file to binary directory
add_custom_command(
	TARGET ${EXE_NAME} POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	${PTXAS_BIN} -arch=sm_20 kernel.ptx -o kernel.o
	COMMENT "Generating kernel Obj files..."
)

# Generate ASM file to binary directory
add_custom_command(
	TARGET ${EXE_NAME} POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	${CUOBJDUMP_BIN} --dump-sass kernel.o > kernel.asm
	COMMENT "Generating kernel Asm files..."
)
