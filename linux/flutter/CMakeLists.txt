cmake_minimum_required(VERSION 3.13)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

add_library(flutter_wrapper_plugin STATIC
  "${EPHEMERAL_DIR}/cpp_client_wrapper/core_implementations.cc"
  "${EPHEMERAL_DIR}/cpp_client_wrapper/standard_codec.cc"
  "${EPHEMERAL_DIR}/cpp_client_wrapper/plugin_registrar.cc"
)

apply_standard_settings(flutter_wrapper_plugin)
target_include_directories(flutter_wrapper_plugin PUBLIC
  "${EPHEMERAL_DIR}"
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include"
)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter)

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)

add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}")
add_dependencies(flutter flutter_assemble)

add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
)
