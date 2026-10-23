function(auroraos_generate)
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
        message(FATAL_ERROR "Aurora requires a Linux target toolchain")
    endif()
    if(NOT ARCH_NAME MATCHES "^(arm32|arm64)$")
        message(FATAL_ERROR "Aurora supports arm32 and arm64")
    endif()
    set(compiler_arguments)
    if(CMAKE_CXX_COMPILER_ARG1)
        separate_arguments(compiler_arguments NATIVE_COMMAND "${CMAKE_CXX_COMPILER_ARG1}")
    endif()
    if(CMAKE_CXX_COMPILER_TARGET)
        list(APPEND compiler_arguments "--target=${CMAKE_CXX_COMPILER_TARGET}")
    endif()
    execute_process(COMMAND "${CMAKE_CXX_COMPILER}" ${compiler_arguments} -dumpmachine
        OUTPUT_VARIABLE compiler_target OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE compiler_result)
    if(NOT compiler_result EQUAL 0 OR
       (ARCH_NAME STREQUAL "arm64" AND NOT compiler_target MATCHES "^aarch64") OR
       (ARCH_NAME STREQUAL "arm32" AND NOT compiler_target MATCHES "^arm"))
        message(FATAL_ERROR "Aurora ${ARCH_NAME} requires a matching target compiler, got ${compiler_target}")
    endif()
    target_compile_definitions(godot-cpp PUBLIC AURORAOS_ENABLED UNIX_ENABLED)
    set_target_properties(godot-cpp PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_link_options(godot-cpp INTERFACE "-Wl,--enable-new-dtags" "-Wl,--gc-sections")
    if(GODOTCPP_USE_HOT_RELOAD)
        target_compile_options(godot-cpp PUBLIC "$<$<CXX_COMPILER_ID:GNU>:-fno-gnu-unique>")
    endif()
    common_compiler_flags()
endfunction()

# Apply to EACH extension and private dependency, not just the outer DSO.
function(auroraos_private_library target)
    set_target_properties(${target} PROPERTIES
        POSITION_INDEPENDENT_CODE ON
        BUILD_RPATH "$ORIGIN"
        INSTALL_RPATH "$ORIGIN"
        BUILD_RPATH_USE_ORIGIN ON
        BUILD_WITH_INSTALL_RPATH ON
        INSTALL_RPATH_USE_LINK_PATH OFF
    )
    target_link_options(${target} PRIVATE "-Wl,--enable-new-dtags")
endfunction()
