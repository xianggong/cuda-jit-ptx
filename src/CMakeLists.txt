set( FOLDER_NAME src )
set( SUBDIRECTORIES 
  inst_sched_0 
  inst_sched_1 
  inst_sched_2 
  inst_sched_3 
  inst_sched_4 
  inst_sched_5
  sample
  special_registers
)

set(CMAKE_SUPPRESS_REGENERATION TRUE)
cmake_minimum_required( VERSION 2.6.0 )
project( ${FOLDER_NAME} )

###############################################################

# Group samples by folder
set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set( FOLDER_GROUP ${FOLDER_GROUP}/${FOLDER_NAME} )

foreach( subdir ${SUBDIRECTORIES} )
    add_subdirectory( ${subdir} )
endforeach( subdir )

