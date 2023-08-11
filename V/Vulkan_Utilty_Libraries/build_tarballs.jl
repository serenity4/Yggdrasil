using BinaryBuilder, Pkg

name = "Vulkan_Utility_Libraries"
version = v"1.3.243"

sources = [
    GitSource("https://github.com/KhronosGroup/Vulkan-Utility-Libraries.git", "79d5fb108be1a013135d3aa9a88c38f0b0608e87")
]

script = raw"""
cd Vulkan-Utility-Libraries

install_license LICENSE.md

CMAKE_FLAGS=()

# Setup cross-compilation toolchain
CMAKE_FLAGS+=(-DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Release build
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=${libdir})

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# X11 is not available on armv6l
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())
platforms = [Platform("x86_64", "linux"; libc="glibc")] # XXX

# The products that we will ensure are always built
products = Product[
    FileProduct("lib/libVulkanLayerSettings.a", :libVulkanLayerSettings)
]

# Some dependencies are needed only on Linux or Linux and FreeBSD
linux = filter(Sys.islinux, platforms)
linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Vulkan_Headers_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
