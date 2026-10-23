# Aurora GDExtension hot reload fixture

This opt-in editor plugin holds a native `RefCounted` object with a stored integer
property. Two ABI-compatible builds return different code revisions. Reload must
switch code while preserving the Godot ObjectID and property value 73.

From this directory, build **both** variants for each needed architecture:

```sh
scons platform=linux arch=x86_64 build_profile=profile.json use_static_cpp=no fixture_revision=1 -j8
scons platform=linux arch=x86_64 build_profile=profile.json use_static_cpp=no fixture_revision=2 -j8
```

For Aurora run the same commands with `platform=auroraos arch=arm64` or `arm32`
inside the matching SDK/SB2 target, using host Python/SCons. The fixture enables
godot-cpp hot-reload accounting by default. `bin/<arch>/revision1` and `revision2`
are separate completed outputs; they never overwrite a library mapped by a running
editor. The selected live library is `project/bin/<arch>/libaurora_reload.so`.

Desktop Linux acceptance:

```sh
python3 run.py --editor /path/to/godot-editor --cycles 6
```

The driver starts its own headless editor, alternates completed SOs by atomic
rename, requests `GDExtensionManager.reload_extension`, checks current code,
state/ObjectID and absence of old deleted DSO mappings in `/proc/PID/maps`, then
quits its editor. Results and logs are local ignored artifacts. Never link directly
over a live mapped DSO: truncating the old inode can crash the process.

CMake, from the godot-cpp root inside the matching Aurora target:

```sh
cmake -S examples/aurora_hot_reload -B cmake-build-reload-arm64-r1 \
  -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_BUILD_TYPE=Debug -DGODOTCPP_USE_STATIC_CPP=OFF \
  -DPython3_EXECUTABLE=/path/to/host/python3.12 -DAURORA_RELOAD_REVISION=1
cmake --build cmake-build-reload-arm64-r1 -j8
```

Use a separate build directory with `AURORA_RELOAD_REVISION=2` for the other
variant. ARM32 uses `CMAKE_SYSTEM_PROCESSOR=armv7`. CMake explicitly enables
`GODOTCPP_USE_HOT_RELOAD`; Aurora applies `-fno-gnu-unique` for GNU C++ builds.
Inspect the built ELF for matching ABI, `$ORIGIN` RUNPATH and no GNU UNIQUE symbols.

For device testing, copy the project and matching ARM variants to a dedicated
writable test project. Start an editor build, then use the same atomic-copy and
command-file protocol as `run.py`. `.aurora-reload-result.json` records the PID,
sequence, revision, reload status and retained state. A quit command has a newer
`sequence` and `"quit": true`. Check the real process's maps after every reload.
Test a developer launch and normal application sandbox separately; writable files
alone do not guarantee executable-code permission. Device file transfer tools are
test tooling, not a product dependency.

This fixture has no native worker threads or external callbacks. It does not
qualify arbitrary extensions for unloading, dependency-only reloads, incompatible
ABI changes or live updates to signed read-only RPM content. Those require
extension-specific cleanup or an application restart.

Verified so far: six desktop Linux reloads preserve current code, ObjectID and
state without old deleted DSO mappings. SCons builds both code revisions for
ARM32 and ARM64; CMake builds revision 1 for both. All six ARM outputs have the
matching ABI, exactly `$ORIGIN` RUNPATH and no GNU UNIQUE symbols. CMake propagates
hot-reload defines/options to both the bindings and extension. Aurora device
execution remains pending; compilation is not device acceptance.
