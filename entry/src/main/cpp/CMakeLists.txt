# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(fastkitdemo)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
  include(${PACKAGE_FIND_FILE})
endif()

add_library(fastkit SHARED napi_init.cpp)

target_include_directories(fastkit PRIVATE ${NATIVERENDER_ROOT_PATH})

target_link_libraries(fastkit PUBLIC libace_napi.z.so libhilog_ndk.z.so libdl.so)
