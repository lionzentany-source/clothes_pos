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


### Copy required native DLLs next to the runner executable if present
# Note: CMAKE_SOURCE_DIR here is windows/runner. Compute project root and windows dir.
set(PROJECT_ROOT "${CMAKE_SOURCE_DIR}/..")
set(UHF_DLL_PROJECT_ROOT "${PROJECT_ROOT}/../UHF Desk Reader SDK/API/UHFPrimeReader.dll")
set(UHF_DLL_WINDOWS_DIR "${PROJECT_ROOT}/UHF Desk Reader SDK/API/UHFPrimeReader.dll")
set(HID_DLL_PROJECT_ROOT "${PROJECT_ROOT}/../hidapi.dll")
set(HID_DLL_WINDOWS_DIR "${PROJECT_ROOT}/hidapi.dll")

function(copy_if_exists SRC_NAME SRC_PATH)
  if (EXISTS "${SRC_PATH}")
    add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E echo "Copying ${SRC_NAME}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SRC_PATH}" "$<TARGET_FILE_DIR:${BINARY_NAME}>/${SRC_NAME}"
      VERBATIM)
    return()
  endif()
endfunction()

# Try UHFPrimeReader.dll (project root then windows/)
if (EXISTS "${UHF_DLL_PROJECT_ROOT}")
  copy_if_exists("UHFPrimeReader.dll" "${UHF_DLL_PROJECT_ROOT}")
elseif (EXISTS "${UHF_DLL_WINDOWS_DIR}")
  copy_if_exists("UHFPrimeReader.dll" "${UHF_DLL_WINDOWS_DIR}")
else()
  message(WARNING "UHFPrimeReader.dll not found. Place it under '<project root>/UHF Desk Reader SDK/API/' or under '<project root>/windows/UHF Desk Reader SDK/API/'.")
endif()

# Try hidapi.dll (project root then windows/)
if (EXISTS "${HID_DLL_PROJECT_ROOT}")
  copy_if_exists("hidapi.dll" "${HID_DLL_PROJECT_ROOT}")
elseif (EXISTS "${HID_DLL_WINDOWS_DIR}")
  copy_if_exists("hidapi.dll" "${HID_DLL_WINDOWS_DIR}")
else()
  message(WARNING "hidapi.dll not found at project root or windows/. Ensure it is bundled next to the EXE for Windows builds.")
endif()
