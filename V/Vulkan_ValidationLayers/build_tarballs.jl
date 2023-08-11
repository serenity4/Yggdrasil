using BinaryBuilder

name = "Vulkan_Validation_Layers"

version = v"1.3.250"
source = "https://github.com/KhronosGroup/Vulkan-ValidationLayers.git"
commit = "d6c1e5a5a6229b52c20c643ff626a948d4850865" # June 29th, 2023

sources = [
    GitSource(source, commit),
    # DirectorySource("./patches"),
    # For tests.
    # GitSource("https://github.com/KhronosGroup/Vulkan-Loader", "71254bedeef4b9e94f7a51ec0fe6e4134dbfcfec"),
]

script = raw"""
cd Vulkan-ValidationLayers

# Remove architecture-specific flags.
# atomic_patch -p1 ${WORKSPACE}/srcdir/remove_march.patch

CXX_FLAGS=()
CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# CMAKE_FLAGS+=(-DVULKAN_HEADERS_INSTALL_DIR=<path of Vulkan_Headers_jll>) # might be necessary

# Work around undefined `cinttypes` printing macros.
# CXX_FLAGS+="-D__STDC_FORMAT_MACROS"

# TODO: Include unit tests.
# CMAKE_FLAGS+=(-DBUILD_TESTS=ON)

# Handle Mac SDK <10.12 errors.
if [[ "${target}" == *-apple-* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.12
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)
fi

if [[ "${target}" == *-mingw* ]]; then
    find . -type f -exec sed -i 's/include <Windows\.h>/include <windows\.h>/g' {} +
    CXX_FLAGS+=" -DHAVE_UNISTD"
fi

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS="${CXX_FLAGS}"
ninja -C build -j ${nproc} install

install_license LICENSE.txt
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("x86_64", "macos"),
    # TODO: Build on Windows.
    # Might want to take some inspiration from https://github.com/google/gfbuild-swiftshader/blob/master/build.sh
    # Platform("x86_64", "windows"),
]

# platforms = expand_cxxstring_abis(platforms)

products = [
    FileProduct("explicit_layer.d", :explicit_layer), # at $install_dir/share/vulkan/, except for Windows, which is at $install_dir/bin/
    LibraryProduct("libvulkan", :libvulkan), # at $install_dir/lib/, except for Windows, which is at $install_dir/bin/
]

build_dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency("Vulkan_Headers_jll"),
    BuildDependency("SPIRV_Headers_jll"),
    Dependency("SPIRV_Tools_jll"),
    Dependency("robin_hood_hashing_jll"),

    # Linux-specific dependencies
    Dependency("Wayland_jll"),
    ## The `xorg-dev` package is listed in the build instructions,
    ## but let's try to avoid pulling in all the Xorg libraries just for WSI.
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libxcb_jll"),
    # Is it needed?
    Dependency("Xorg_xproto_jll"),
    # Dependency("Xorg_xcb_proto_jll"),

    # Windows-specific dependencies
    # NOTE: build instructions rely on the Visual Studio GUI
    ## For 64-bit Windows only
    # Dependency("mimalloc_jll"),
]

test_dependencies = [
    BuildDependency("Vulkan_Loader_jll"),
    BuildDependency("GoogleTest_jll"),
    BuildDependency("glslang_jll"),
]

# Dependencies that must be installed before this package can be built
# dependencies = [build_dependencies; test_dependencies]
dependencies = build_dependencies

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
