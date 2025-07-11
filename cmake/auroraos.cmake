#[=======================================================================[.rst:
AuroraOS
--------

This file contains functions for options and configuration for targeting the
AuroraOS platform

]=======================================================================]

#[=============================[ AuroraOS Options ]=============================]
function(auroraos_options)
    #[[ Options from SCons
    use_llvm : Use the LLVM compiler
        Not implemented as compiler selection is managed by CMake. Look to
        doc/cmake.rst for examples.
    ]]
endfunction()

#[===========================[ Target Generation ]===========================]
function(auroraos_generate)
    target_compile_definitions(godot-cpp PUBLIC AURORAOS_ENABLED UNIX_ENABLED)

    common_compiler_flags()
endfunction() 