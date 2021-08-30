set(X264_VERSION 157)

vcpkg_fail_port_install(ON_ARCH "arm")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO mirror/x264
    REF 303c484ec828ed0d8bfe743500e70314d026c3bd
    SHA512 faf210a3f9543028ed882c8348b243dd7ae6638e7b3ef43bec1326b717f23370f57c13d0ddb5e1ae94411088a2e33031a137b68ae9f64c18f8f33f601a0da54d
    HEAD_REF master
    PATCHES 
        "uwp-cflags.patch"
)

vcpkg_find_acquire_program(NASM)
get_filename_component(NASM_EXE_PATH ${NASM} DIRECTORY)
vcpkg_add_to_path(${NASM_EXE_PATH})

if(VCPKG_TARGET_IS_WINDOWS)
    _vcpkg_determine_autotools_host_cpu(BUILD_ARCH)
    _vcpkg_determine_autotools_target_cpu(HOST_ARCH)
    list(APPEND OPTIONS --build=${BUILD_ARCH}-pc-mingw32)
    list(APPEND OPTIONS --host=${HOST_ARCH}-pc-mingw32)
    set(ENV{AS} "${NASM}")
endif()

if(VCPKG_TARGET_IS_UWP)
    list(APPEND OPTIONS --extra-cflags=-DWINAPI_FAMILY=WINAPI_FAMILY_APP --extra-cflags=-D_WIN32_WINNT=0x0A00)
    list(APPEND OPTIONS --extra-ldflags=-APPCONTAINER --extra-ldflags=WindowsApp.lib)
    list(APPEND OPTIONS --disable-asm)
endif()

if(VCPKG_TARGET_IS_LINUX)
    list(APPEND OPTIONS --enable-pic)
endif()

vcpkg_make_configure(
    SOURCE_PATH ${SOURCE_PATH}
    NO_ADDITIONAL_PATHS
    OPTIONS
        ${OPTIONS}
        --enable-strip
        --disable-lavf
        --disable-swscale
        --disable-avs
        --disable-ffms
        --disable-gpac
        --disable-lsmash
        --enable-debug

)

vcpkg_make_install()

if(NOT VCPKG_TARGET_IS_UWP)
    vcpkg_copy_tools(TOOL_NAMES x264 AUTO_CLEAN)
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

if(VCPKG_TARGET_IS_WINDOWS)
    set(pcfile "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/x264.pc")
    if(EXISTS "${pcfile}")
        vcpkg_replace_string("${pcfile}" "-lx264" "-llibx264")
    endif()
    set(pcfile "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/x264.pc")
    if(EXISTS "${pcfile}")
        vcpkg_replace_string("${pcfile}" "-lx264" "-llibx264")
    endif()
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic" AND VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libx264.dll.lib ${CURRENT_PACKAGES_DIR}/lib/libx264.lib)
    file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libx264.dll.lib ${CURRENT_PACKAGES_DIR}/debug/lib/libx264.lib)
elseif(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    # force U_STATIC_IMPLEMENTATION macro
    file(READ ${CURRENT_PACKAGES_DIR}/include/x264.h HEADER_CONTENTS)
    string(REPLACE "defined(U_STATIC_IMPLEMENTATION)" "1" HEADER_CONTENTS "${HEADER_CONTENTS}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/include/x264.h "${HEADER_CONTENTS}")

    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/bin
        ${CURRENT_PACKAGES_DIR}/debug/bin
    )
endif()

vcpkg_fixup_pkgconfig()

vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
