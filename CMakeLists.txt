cmake_minimum_required(VERSION 3.25)

# PROJECT_SOURCE_DIR isn't Simul's yet: before project() it is the embedding project's.
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/git-version.cmake)
simul_resolve_version(simul_version)

project(Simul
    VERSION ${simul_version}
    DESCRIPTION "Client-server framework for real-time collaborative editing"
    LANGUAGES CXX)

# These variables are directory-scoped: they apply to Simul only, not to a project that embeds it.
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
# The SurfaceEditor plugin is a shared library that links Simul's static libraries.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Built on its own, everything is enabled. Embedded with add_subdirectory (SurfaceEditor), only the
# libraries are built, and warnings don't break the host's build.
option(SIMUL_BUILD_APPS "Build simul-server and simul-bot" ${PROJECT_IS_TOP_LEVEL})
option(SIMUL_BUILD_TESTS "Build simul-tests" ${PROJECT_IS_TOP_LEVEL})
option(SIMUL_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" ${PROJECT_IS_TOP_LEVEL})

# Passed in by CI (-DSIMUL_BUILD_SHA=<sha>); not read from git, because the Docker build has no .git.
set(SIMUL_BUILD_SHA "unknown" CACHE STRING "Git commit this build comes from")

include(${PROJECT_SOURCE_DIR}/cmake/compiler-warnings.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/dependencies.cmake)

add_subdirectory(libs/common)
add_subdirectory(libs/protocol)
add_subdirectory(libs/net)
add_subdirectory(libs/server-core)
add_subdirectory(libs/client)

if(SIMUL_BUILD_APPS)
    add_subdirectory(apps/simul-server)
    add_subdirectory(apps/simul-bot)
endif()

if(SIMUL_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
