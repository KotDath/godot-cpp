"""Aurora target ABI comes from its SDK compiler, not the build host."""

import shlex
import subprocess

import ar_tempfile
import common_compiler_flags
from SCons.Errors import UserError


def options(opts):
    opts.Add("aurora_toolchain_prefix", "Cross-tool prefix (empty under SB2)", "")
    opts.Add("aurora_sysroot", "Target sysroot (empty under SB2)", "")


def exists(env):
    return True


def generate(env):
    if env["arch"] not in ("arm32", "arm64"):
        raise UserError("Aurora supports arm32 and arm64")
    prefix = env["aurora_toolchain_prefix"]
    if prefix:
        for name, tool in (("CC", "gcc"), ("CXX", "g++"), ("AR", "ar"), ("RANLIB", "ranlib")):
            env[name] = prefix + tool
    machine = subprocess.check_output(shlex.split(env["CXX"]) + ["-dumpmachine"], text=True).strip()
    expected = "aarch64" if env["arch"] == "arm64" else "arm"
    if not machine.startswith(expected):
        raise UserError("Compiler {} does not match {}".format(machine, env["arch"]))
    if env["aurora_sysroot"]:
        flag = "--sysroot=" + env["aurora_sysroot"]
        env.Append(CCFLAGS=[flag], LINKFLAGS=[flag])
    env.Append(CCFLAGS=["-fPIC", "-Wwrite-strings"])
    env.Append(CPPDEFINES=["AURORAOS_ENABLED", "UNIX_ENABLED"])
    # Every private DSO needs its own RUNPATH; this is not transitive.
    env.Append(LINKFLAGS=["-Wl,--enable-new-dtags", "-Wl,-rpath,'$$ORIGIN'", "-Wl,--gc-sections"])
    if env.use_hot_reload:
        env.Append(CXXFLAGS=["-fno-gnu-unique"])
    if env["lto"] == "auto":
        env["lto"] = "none"
    ar_tempfile.configure(env)
    common_compiler_flags.generate(env)
