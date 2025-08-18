cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)


# Copy UHFPrimeReader.dll next to the runner executable if present
# Try project root first, then the windows/ directory
# CMAKE_SOURCE_DIR here is windows/runner. Compute project root and windows dir.
set(UHF_DLL_SOURCE_PROJECT_ROOT "${CMAKE_SOURCE_DIR}/../../UHF Desk Reader SDK/API/UHFPrimeReader.dll")
set(UHF_DLL_SOURCE_WINDOWS_DIR "${CMAKE_SOURCE_DIR}/../UHF Desk Reader SDK/API/UHFPrimeReader.dll")

if (EXISTS "${UHF_DLL_SOURCE_PROJECT_ROOT}")
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "Copying UHFPrimeReader.dll from project root"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${UHF_DLL_SOURCE_PROJECT_ROOT}" "$<TARGET_FILE_DIR:${BINARY_NAME}>/UHFPrimeReader.dll"
    VERBATIM
  )
elseif (EXISTS "${UHF_DLL_SOURCE_WINDOWS_DIR}")
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "Copying UHFPrimeReader.dll from windows/"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${UHF_DLL_SOURCE_WINDOWS_DIR}" "$<TARGET_FILE_DIR:${BINARY_NAME}>/UHFPrimeReader.dll"
    VERBATIM
  )
else()
  message(WARNING "UHFPrimeReader.dll not found. Place it under '<project root>/UHF Desk Reader SDK/API/' or under '<project root>/windows/UHF Desk Reader SDK/API/'.")
endif()
