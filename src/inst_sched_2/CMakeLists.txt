set ( EXE_NAME inst_sched_2 )
set ( SRC_FILES inst_sched_2.cpp )
set ( EXTRA_CLEAN_FILES kernel0.ptx kernel0.o kernel0.asm kernel1.ptx kernel1.o kernel1.asm)

# Extra files for make clean. Dont forget "", otherwise won't work
set_directory_properties (
	PROPERTIES
	ADDITIONAL_MAKE_CLEAN_FILES "${EXTRA_CLEAN_FILES}"
)

# Generate host program
add_executable(${EXE_NAME} ${SRC_FILES})
target_link_libraries(${EXE_NAME} cuda cudart)

# Generate PTX file to binary directory
add_custom_command(
	TARGET ${EXE_NAME} POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	llc -mcpu=sm_20 ${CMAKE_CURRENT_SOURCE_DIR}/kernel0.ll 
        -o kernel0.ptx
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	llc -mcpu=sm_20 ${CMAKE_CURRENT_SOURCE_DIR}/kernel1.ll 
        -o kernel1.ptx
	COMMENT "Generating kernel PTX files..."
)

# Generate OBJ file to binary directory
add_custom_command(
	TARGET ${EXE_NAME} POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	${PTXAS_BIN} -arch=sm_20 kernel0.ptx -o kernel0.o
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	${PTXAS_BIN} -arch=sm_20 kernel1.ptx -o kernel1.o
	COMMENT "Generating kernel Obj files..."
)

# Generate ASM file to binary directory
add_custom_command(
	TARGET ${EXE_NAME} POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	${CUOBJDUMP_BIN} --dump-sass kernel0.o > kernel0.asm
	COMMAND ${CMAKE_COMMAND} -E chdir ./ 
	${CUOBJDUMP_BIN} --dump-sass kernel1.o > kernel1.asm
	COMMENT "Generating kernel Asm files..."
)
