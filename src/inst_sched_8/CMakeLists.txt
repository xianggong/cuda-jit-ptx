set (EXE_NAME inst_sched_8) 
set (SRC_FILES inst_sched_8.cpp)
set (GENERATOR_FILES run.sh gen_kernel.py kernel.tpl kernelRead.tpl)

# Generate host program
add_executable(${EXE_NAME} ${SRC_FILES})
target_link_libraries(${EXE_NAME} cuda)

# Copy extra files 
foreach (generator_file ${GENERATOR_FILES})
	add_custom_command(
		TARGET ${EXE_NAME} POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_if_different
		${CMAKE_CURRENT_SOURCE_DIR}/${generator_file} ./ 
	)
endforeach (generator_file)

add_custom_target(clean rm -rf *.ll *.ptx *.o *.asm)
