# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter build.
list(APPEND FLUTTER_TARGET_PLATFORM_SYSROOT "")

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

# Set fallback configurations for older versions of the flutter tool.
if (NOT DEFINED FLUTTER_TARGET_PLATFORM)
  set(FLUTTER_TARGET_PLATFORM "windows-x64")
endif()

list(APPEND FLUTTER_LIBRARY_NAME "flutter_windows.dll")
list(APPEND FLUTTER_LIBRARY "${EPHEMERAL_DIR}/${FLUTTER_LIBRARY_NAME}")
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "flutter_export.h"
  "flutter_windows.h"
  "flutter_messenger.h"
  "flutter_plugin_registrar.h"
  "flutter_texture_registrar.h"
)
list(TRANSFORM FLUTTER_LIBRARY_HEADERS PREPEND "${EPHEMERAL_DIR}/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE "${EPHEMERAL_DIR}")
target_link_libraries(flutter INTERFACE "${EPHEMERAL_DIR}/flutter_windows.dll.lib")
add_dependencies(flutter flutter_assemble)

set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../build" PARENT_SCOPE)

add_library(flutter_wrapper_app STATIC
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/core_implementations.cc"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/plugin_registrar.cc"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/flutter_engine.cc"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/flutter_view_controller.cc"
)
apply_standard_settings(flutter_wrapper_app)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
target_include_directories(flutter_wrapper_app PUBLIC
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include"
)
add_dependencies(flutter_wrapper_app flutter_assemble)

add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
)
