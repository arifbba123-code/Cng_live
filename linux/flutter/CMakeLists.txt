# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter build.
list(APPEND FLUTTER_TARGET_PLATFORM_SYSROOT "")

# Set up the build target(s).
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

file(GLOB FLUTTER_LIBRARY "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")

set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../build" PARENT_SCOPE)

add_custom_target(flutter_assemble
  COMMAND ${CMAKE_COMMAND} -E env
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../bin/flutter
    build linux
  VERBATIM
)
