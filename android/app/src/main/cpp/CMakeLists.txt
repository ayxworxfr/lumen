cmake_minimum_required(VERSION 3.22.1)
project(lumen_avif CXX)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

# Force generic (C-only) CPU before any libaom cmake runs.
# Without this, libaom auto-detects aarch64 → arm64 and tries to enable_language(ASM),
# which looks for `as` assembler — not in PATH during Windows cross-compilation.
set(AOM_TARGET_CPU    "generic" CACHE STRING "" FORCE)
set(BUILD_SHARED_LIBS OFF       CACHE BOOL   "" FORCE)
set(ENABLE_TESTS      OFF       CACHE BOOL   "" FORCE)
set(ENABLE_EXAMPLES   OFF       CACHE BOOL   "" FORCE)
set(ENABLE_DOCS       OFF       CACHE BOOL   "" FORCE)
# CONFIG_AV1_DECODER must stay enabled — libavif codec_aom.c references aom_codec_av1_dx
# even when we only call the encoder path at runtime.

# libavif v1.1.1 — AVIF_LOCAL_AOM=ON lets libavif download and build libaom internally,
# picking up the AOM_TARGET_CPU=generic cache variable set above.
FetchContent_Declare(
    libavif
    GIT_REPOSITORY https://github.com/AOMediaCodec/libavif.git
    GIT_TAG        v1.1.1
    GIT_SHALLOW    TRUE
)
# libavif v1.1.1 API: AVIF_CODEC_AOM="LOCAL" replaces AVIF_CODEC_AOM=ON+AVIF_LOCAL_AOM=ON
set(AVIF_CODEC_AOM "LOCAL" CACHE STRING "" FORCE)
# Disable libyuv — not available in this build env; libavif falls back to its own YUV routines
set(AVIF_LIBYUV    "OFF"   CACHE STRING "" FORCE)
FetchContent_MakeAvailable(libavif)

# lumen_avif.so — JNI wrapper
add_library(lumen_avif SHARED avif_jni.cpp)
target_compile_features(lumen_avif PRIVATE cxx_std_17)
target_include_directories(lumen_avif PRIVATE ${libavif_SOURCE_DIR}/include)
target_link_libraries(lumen_avif PRIVATE avif android log)
