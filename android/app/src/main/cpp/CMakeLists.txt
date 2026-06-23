cmake_minimum_required(VERSION 3.22.1)
project(lumen_avif CXX)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

# ── libaom（AV1 编码后端）────────────────────────────────────
# AOM_TARGET_CPU=generic: prevents libaom from detecting aarch64 and enabling
# ASM language — `as` assembler is not in PATH during Windows cross-compilation.
set(AOM_TARGET_CPU    "generic" CACHE STRING "" FORCE)
set(BUILD_SHARED_LIBS OFF       CACHE BOOL   "" FORCE)
set(ENABLE_TESTS      OFF       CACHE BOOL   "" FORCE)
set(ENABLE_EXAMPLES   OFF       CACHE BOOL   "" FORCE)
set(ENABLE_DOCS       OFF       CACHE BOOL   "" FORCE)

FetchContent_Declare(libaom
    GIT_REPOSITORY https://aomedia.googlesource.com/aom
    GIT_TAG        v3.9.1
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(libaom)

# Register aom in libheif's export set so libheif's install(EXPORT "libheif-config" ...)
# succeeds at generate time — CMake requires all link dependencies of heif to be in
# some export set; FetchContent-built aom has no install rules by default.
install(TARGETS aom EXPORT libheif-config ARCHIVE DESTINATION lib)

# ── 告知 libheif 在哪里找 libaom ────────────────────────────
# libheif 的 cmake/FindAOM.cmake 通过这几个变量定位 libaom；
# FetchContent 构建的 libaom 不会安装到系统路径，需手动注入。
set(AOM_FOUND        TRUE               CACHE BOOL   "" FORCE)
set(AOM_INCLUDE_DIR  "${libaom_SOURCE_DIR}" CACHE PATH "" FORCE)
set(AOM_INCLUDE_DIRS "${libaom_SOURCE_DIR}" CACHE PATH "" FORCE)
set(AOM_LIBRARY      aom                CACHE STRING "" FORCE)
set(AOM_LIBRARIES    aom                CACHE STRING "" FORCE)

# ── libheif ─────────────────────────────────────────────────
FetchContent_Declare(libheif
    GIT_REPOSITORY https://github.com/strukturag/libheif.git
    GIT_TAG        v1.23.0
    GIT_SHALLOW    TRUE
)
# 编解码均使用 libaom（已编译），无需额外解码依赖
set(WITH_EXAMPLES         OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING         OFF CACHE BOOL "" FORCE)
set(ENABLE_PLUGIN_LOADING OFF CACHE BOOL "" FORCE)
set(WITH_LIBDE265         OFF CACHE BOOL "" FORCE)
set(WITH_X265             OFF CACHE BOOL "" FORCE)
set(WITH_SvtEnc           OFF CACHE BOOL "" FORCE)
set(WITH_DAV1D            OFF CACHE BOOL "" FORCE)
set(WITH_RAV1E            OFF CACHE BOOL "" FORCE)
set(WITH_OpenJPEG_DECODER OFF CACHE BOOL "" FORCE)
set(WITH_JPEG_DECODER     OFF CACHE BOOL "" FORCE)
set(WITH_JPEG_ENCODER     OFF CACHE BOOL "" FORCE)
set(WITH_AOM_ENCODER      ON  CACHE BOOL "" FORCE)
set(WITH_AOM_DECODER      ON  CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(libheif)

# ── lumen_avif.so（JNI 包装）────────────────────────────────
add_library(lumen_avif SHARED avif_jni.cpp)
target_compile_features(lumen_avif PRIVATE cxx_std_17)
target_include_directories(lumen_avif PRIVATE
    ${libheif_SOURCE_DIR}/libheif/api
    ${libheif_BINARY_DIR}
)
target_link_libraries(lumen_avif PRIVATE heif android log)
