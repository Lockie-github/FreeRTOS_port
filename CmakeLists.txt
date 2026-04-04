
# =============================================================================
# FreeRTOS Configuration (Official CMake Integration)
# =============================================================================

# Create freertos_config interface library
add_library(freertos_config INTERFACE)
target_include_directories(freertos_config SYSTEM INTERFACE
    ${CMAKE_SOURCE_DIR}
)

# Add FreeRTOS kernel using official CMakeLists.txt
add_subdirectory(FreeRTOS-Kernel)

# Link config to kernel
target_link_libraries(freertos_kernel PUBLIC freertos_config)

# Add freertos_callbacks.c to the kernel
target_sources(freertos_kernel PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/freertos_callbacks.c
)

# Link FreeRTOS kernel to main project
target_link_libraries(${CMAKE_PROJECT_NAME}
    freertos_kernel
)

target_compile_options(freertos_kernel PRIVATE
    ### Gnu/Clang C Options
    $<$<COMPILE_LANG_AND_ID:C,GNU>:-fdiagnostics-color=always>
    $<$<COMPILE_LANG_AND_ID:C,Clang>:-fcolor-diagnostics>

    $<$<COMPILE_LANG_AND_ID:C,Clang,GNU>:-Wall>
    $<$<COMPILE_LANG_AND_ID:C,Clang,GNU>:-Wextra>
    $<$<COMPILE_LANG_AND_ID:C,Clang,GNU>:-Wpedantic>
    $<$<COMPILE_LANG_AND_ID:C,Clang,GNU>:-Werror>
    $<$<COMPILE_LANG_AND_ID:C,Clang,GNU>:-Wconversion>
    $<$<COMPILE_LANG_AND_ID:C,Clang>:-Weverything>

    # Suppressions required to build clean with clang.
    $<$<COMPILE_LANG_AND_ID:C,Clang>:-Wno-unused-macros>
    $<$<COMPILE_LANG_AND_ID:C,Clang>:-Wno-padded>
    $<$<COMPILE_LANG_AND_ID:C,Clang>:-Wno-missing-variable-declarations>
    $<$<COMPILE_LANG_AND_ID:C,Clang>:-Wno-covered-switch-default>
    $<$<COMPILE_LANG_AND_ID:C,Clang>:-Wno-cast-align> )
