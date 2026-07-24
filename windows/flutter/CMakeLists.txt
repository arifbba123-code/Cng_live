cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")
get_filename_component(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}" DIRECTORY)

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")
set(FLUTTER_LIBRARY_HEADERS "${EPHEMERAL_DIR}/cpp_client_wrapper/include")

add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE "${FLUTTER_LIBRARY_HEADERS}")
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

add_library(flutter_wrapper_app STATIC
  "${EPHEMERAL_DIR}/cpp_client_wrapper/core_implementations.cc"
  "${EPHEMERAL_DIR}/cpp_client_wrapper/standard_codec.cc"
  "${EPHEMERAL_DIR}/cpp_client_wrapper/plugin_registrar.cc"
)
apply_standard_settings(flutter_wrapper_app)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
target_include_directories(flutter_wrapper_app PUBLIC "${EPHEMERAL_DIR}/cpp_client_wrapper/include")
add_dependencies(flutter_wrapper_app flutter_assemble)

add_custom_target(flutter_assemble DEPENDS "${FLUTTER_LIBRARY}")
