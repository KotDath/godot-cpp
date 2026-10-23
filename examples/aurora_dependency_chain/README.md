# Aurora native dependency-chain test

`AuroraDependencyProbe.value()` calls middle.so → leaf.so and returns 42.
The project also displays a rotating GLES cube and a touch counter.
API version is 4.7. Build both target architectures separately; object and DSO
paths are architecture-specific. Each DSO has its own `$ORIGIN` RUNPATH.

From this directory, inside the selected SDK/SB2 target:

```sh
/path/to/host/python3.12 -m SCons platform=auroraos arch=arm64 build_profile=profile.json -j8
/path/to/host/python3.12 -m SCons platform=auroraos arch=arm32 build_profile=profile.json -j8
```

Use the matching SDK target (`aarch64` or `armv7hl`). Python and SCons must run
on the build host. The Aurora engine repository provides a pinned bootstrap.
With an explicit toolchain, use `aurora_toolchain_prefix` and `aurora_sysroot`.

For desktop preview, build the host libraries too:

```sh
scons platform=linux arch=x86_64 build_profile=profile.json use_static_cpp=no -j8
```

CMake inside the matching SDK target, from godot-cpp root:

```sh
cmake -S examples/aurora_dependency_chain -B examples/aurora_dependency_chain/build-arm64 \
  -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_BUILD_TYPE=Debug -DPython3_EXECUTABLE=/path/to/host/python3.12
cmake --build examples/aurora_dependency_chain/build-arm64 -j8
cmake --install examples/aurora_dependency_chain/build-arm64 --prefix /path/to/staging
```

For ARM32 use a separate build directory and `CMAKE_SYSTEM_PROCESSOR=armv7`.
For external toolchains supply a CMake toolchain file with compiler and sysroot.
`GODOTCPP_AURORAOS=ON` selects the Aurora platform independently of Linux host
behavior; CMake derives architecture from the target processor. The helper
`auroraos_private_library(target)` sets PIC and `$ORIGIN` for each private DSO.

Use the engine's **Aurora OS** export preset to build an RPM from `project/`.
The packager checks architecture, hard-float ABI, SONAME collisions and the
complete DT_NEEDED chain. Libraries are private to the app and never installed
into global `/usr/lib`. Do not copy host libraries into a target package.
