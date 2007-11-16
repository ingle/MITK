#
# Create a core library (Algorithms, DataStructures etc.)
# 
# No parameters. Expects files.cmake in the same directory and CMake
# variables LIBPOSTFIX and KITNAME to be set correctly
#
MACRO(CREATE_CORE_LIB)
  INCLUDE(files.cmake)
  IF(MITK_CMAKE_DEBUG)
    FILE(GLOB_RECURSE CPP_FILES_GLOB RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cpp)
    FOREACH(CPP_FILE ${CPP_FILES})  
      IF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${CPP_FILE})
        LIST(REMOVE_ITEM CPP_FILES_GLOB ${CPP_FILE}) 
      ELSE(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${CPP_FILE})
        # this does not work since there are some generated files added by template macro
        # MESSAGE(STATUS "WARNING: referenced file from files.cmake does not exist: ${CPP_FILE}")
        # LIST(REMOVE_ITEM CPP_FILES ${CPP_FILE}) 
      ENDIF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${CPP_FILE})
    ENDFOREACH(CPP_FILE)
    IF(CPP_FILES_GLOB)
      MESSAGE(STATUS "WARNING: possibly obsolete files: ${CPP_FILES_GLOB}")
    ENDIF(CPP_FILES_GLOB)
  ENDIF(MITK_CMAKE_DEBUG)
  IF(MITK_USE_GLOBBING)
    FILE(GLOB_RECURSE CPP_FILES_GLOB RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cpp)
    SET(CPP_FILES ${CPP_FILES_GLOB})
  ENDIF(MITK_USE_GLOBBING)

  GET_FILENAME_COMPONENT(LIBNAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
  SET(LIBNAME mitk${LIBNAME}${LIBPOSTFIX})
  ADD_LIBRARY(${LIBNAME} ${CPP_FILES})
  TARGET_LINK_LIBRARIES(${LIBNAME} ${LIBRARIES_FOR_${KITNAME}_CORE})
ENDMACRO(CREATE_CORE_LIB)

MACRO(CREATE_QMITK)
  SUPPRESS_VC8_DEPRECATED_WARNINGS()
  INCLUDE(files.cmake)
  INCLUDE_DIRECTORIES(${Q${KITNAME}_INCLUDE_DIRS})
  ADD_DEFINITIONS(${QT_DEFINITIONS})
  IF(UI_FILES)
  QT_WRAP_UI(Qmitk${LIBPOSTFIX} Q${KITNAME}_GENERATED_H Q${KITNAME}_GENERATED_CPP ${UI_FILES})
  ENDIF(UI_FILES)
  IF(MOC_H_FILES)
  QT_WRAP_CPP(Qmitk${LIBPOSTFIX} Q${KITNAME}_GENERATED_CPP ${MOC_H_FILES})

  ENDIF(MOC_H_FILES)
  ADD_LIBRARY(Qmitk${LIBPOSTFIX} ${CPP_FILES} ${Q${KITNAME}_GENERATED_CPP})
  TARGET_LINK_LIBRARIES(Qmitk${LIBPOSTFIX} ${QT_LIBRARIES} ${${KITNAME}_CORE_LIBRARIES})
ENDMACRO(CREATE_QMITK)

MACRO(APPLY_VTK_FLAGS)
  IF(NOT MITK_VTK_FLAGS_APPLIED)
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${VTK_REQUIRED_C_FLAGS}")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${VTK_REQUIRED_CXX_FLAGS}")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${VTK_REQUIRED_EXE_LINKER_FLAGS}")
    SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${VTK_REQUIRED_SHARED_LINKER_FLAGS}")
    SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${VTK_REQUIRED_MODULE_LINKER_FLAGS}")
    SET(MITK_VTK_FLAGS_APPLIED 1)
  ENDIF(NOT MITK_VTK_FLAGS_APPLIED)
ENDMACRO(APPLY_VTK_FLAGS)

# increase heap limit for MSVC70. Assumes /Zm1000 is set by ITK
MACRO(INCREASE_MSVC_HEAP_LIMIT)
IF(MSVC70)
 STRING(REPLACE /Zm1000 /Zm1200 CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})  
ENDIF(MSVC70)
ENDMACRO(INCREASE_MSVC_HEAP_LIMIT)

# suppress some warnings in VC8 about using unsafe/deprecated c functions
MACRO(SUPPRESS_VC8_DEPRECATED_WARNINGS)
IF(MSVC80)
  ADD_DEFINITIONS(-D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS)
ENDIF(MSVC80)
ENDMACRO(SUPPRESS_VC8_DEPRECATED_WARNINGS)

INCLUDE(${CMAKE_ROOT}/Modules/TestCXXAcceptsFlag.cmake)
MACRO(CHECK_AND_SET flag sourcelist )
  CHECK_CXX_ACCEPTS_FLAG(${flag} R)
  IF(R)
    SET_SOURCE_FILES_PROPERTIES(
      ${${sourcelist}}
       PROPERTIES
       COMPILE_FLAGS ${flag}
      )
  ENDIF(R)
ENDMACRO(CHECK_AND_SET)

#
# MITK_MULTIPLEX_PICTYPE: generate separated source files for different
# data types to reduce memory consumption of compiler during template 
# instantiation
#
# Param "file" should be named like mitkMyAlgo-TYPE.cpp
# in the file, every occurence of @TYPE@ is replaced by the
# datatype. For each datatype, a new file mitkMyAlgo-datatype.cpp 
# is generated and added to CPP_FILES. Use this macro in files.cmake after
# creating the CPP_FILES variable.
#
MACRO(MITK_MULTIPLEX_PICTYPE file)
  SET(TYPES "double;float;int;unsigned int;short;unsigned short;char;unsigned char")
  FOREACH(TYPE ${TYPES})
    # create filename for destination
    STRING(REPLACE " " "_" quoted_type "${TYPE}")
    STRING(REPLACE TYPE ${quoted_type} quoted_file ${file})
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/${file} ${CMAKE_CURRENT_BINARY_DIR}/${quoted_file} @ONLY)
    SET(CPP_FILES ${CPP_FILES} ${CMAKE_CURRENT_BINARY_DIR}/${quoted_file})
  ENDFOREACH(TYPE)
ENDMACRO(MITK_MULTIPLEX_PICTYPE)
