vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO eclipse/paho.mqtt.c
  REF "v${VERSION}"
  SHA512 3152b557a8ab7c9b9c80277283e0f5e9965ce4c2ebbdaef0f238908d49e6fa1281aa72932ea112a836144b79656e4abe6e0cbd93840429a52e501a2c6b12d313
  HEAD_REF master
  PATCHES
    fix-unresolvedsymbol-arm.patch
    fix-ODR-libuuid-linux.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" PAHO_BUILD_STATIC)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" PAHO_BUILD_DYNAMIC)

vcpkg_replace_string("${SOURCE_PATH}/src/CMakeLists.txt" [[SET(OPENSSL_ROOT_DIR "" CACHE PATH "Directory containing OpenSSL libraries and includes")]] "")

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DPAHO_WITH_SSL=TRUE
    -DPAHO_BUILD_SHARED=${PAHO_BUILD_DYNAMIC}
    -DPAHO_BUILD_STATIC=${PAHO_BUILD_STATIC}
    -DPAHO_ENABLE_TESTING=FALSE
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME eclipse-paho-mqtt-c CONFIG_PATH lib/cmake/eclipse-paho-mqtt-c)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    vcpkg_copy_tools(TOOL_NAMES MQTTVersion AUTO_CLEAN)
endif()

if(VCPKG_TARGET_IS_WINDOWS OR VCPKG_TARGET_IS_OSX)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/eclipse-paho-mqtt-c/eclipse-paho-mqtt-cConfig.cmake"
        [[# Generated by CMake]]
        [[# Generated by CMake
    include(CMakeFindDependencyMacro)
    find_dependency(OpenSSL)]]
    )   
else()
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/eclipse-paho-mqtt-c/eclipse-paho-mqtt-cConfig.cmake"
        [[# Generated by CMake]]
        [[# Generated by CMake
    include(CMakeFindDependencyMacro)
    find_dependency(OpenSSL)
    find_dependency(unofficial-libuuid CONFIG)]]
    )
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/doc")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
