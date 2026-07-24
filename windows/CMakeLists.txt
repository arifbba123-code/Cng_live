cmake_minimum_required(VERSION 3.14)
project(cng_live LANGUAGES CXX)

set(BINARY_NAME "cng_live")

cmake_policy(SET CMP0063 NEW)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
endif()

set(CMAKE_SUPPRESS_REGENERATION true)

function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

add_subdirectory("runner")

add_dependencies(${BINARY_NAME} flutter_assemble)
