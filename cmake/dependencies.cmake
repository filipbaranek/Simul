# Third-party libraries, downloaded at configure time.
#
# Keep the tags recent: CMake 4 rejects dependencies whose cmake_minimum_required is below 3.5.
# SYSTEM makes their headers system headers, so warnings inside them don't trigger our -Werror.

include(FetchContent)

FetchContent_Declare(asio
    GIT_REPOSITORY https://github.com/chriskohlhoff/asio.git
    GIT_TAG        asio-1-36-0
    GIT_SHALLOW    TRUE
    SYSTEM)

FetchContent_Declare(spdlog
    GIT_REPOSITORY https://github.com/gabime/spdlog.git
    GIT_TAG        v1.16.0
    GIT_SHALLOW    TRUE
    SYSTEM)

FetchContent_MakeAvailable(asio spdlog)

# Standalone Asio is header-only and has no CMake build, so FetchContent only downloads it and the
# target is defined here.
find_package(Threads REQUIRED)
add_library(simul-asio INTERFACE)
add_library(asio::asio ALIAS simul-asio)
target_include_directories(simul-asio SYSTEM INTERFACE ${asio_SOURCE_DIR}/asio/include)
target_compile_definitions(simul-asio INTERFACE ASIO_STANDALONE)
target_link_libraries(simul-asio INTERFACE Threads::Threads)

if(SIMUL_BUILD_TESTS)
    FetchContent_Declare(Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.15.3
        GIT_SHALLOW    TRUE
        SYSTEM)

    FetchContent_MakeAvailable(Catch2)
endif()
