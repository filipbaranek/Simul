# Included before project(), which needs the version. -DSIMUL_VERSION=<x.y.z> wins (CI and the
# Docker build, which has no .git); otherwise the latest tag (v1.2.3 or 1.2.3) is used, else 0.0.0.
# A new tag is picked up on the next configure.
set(SIMUL_VERSION "" CACHE STRING "Version override (x.y.z); empty reads the latest git tag")

function(simul_resolve_version out_var)
    if(SIMUL_VERSION)
        if(NOT SIMUL_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
            message(FATAL_ERROR "SIMUL_VERSION must be x.y.z, got '${SIMUL_VERSION}'")
        endif()
        set(${out_var} ${SIMUL_VERSION} PARENT_SCOPE)
        return()
    endif()

    set(${out_var} "0.0.0" PARENT_SCOPE)

    find_package(Git QUIET)
    if(NOT Git_FOUND)
        message(STATUS "Simul version: git not found, using 0.0.0")
        return()
    endif()

    # Only Simul's own repository counts: a copy without .git inside another repository (e.g.
    # SurfaceEditor) would otherwise get that repository's tags.
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --show-toplevel
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE toplevel
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE result
        ERROR_QUIET)
    file(REAL_PATH "${CMAKE_CURRENT_SOURCE_DIR}" source_dir)
    if(result EQUAL 0)
        file(REAL_PATH "${toplevel}" toplevel)
    endif()
    if(NOT result EQUAL 0 OR NOT toplevel STREQUAL source_dir)
        message(STATUS "Simul version: not in Simul's git repository, using 0.0.0")
        return()
    endif()

    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0 --match "v[0-9]*" --match "[0-9]*"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE tag
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE result
        ERROR_QUIET)
    if(NOT result EQUAL 0)
        message(STATUS "Simul version: no version tag, using 0.0.0")
        return()
    endif()

    if(NOT tag MATCHES "^v?([0-9]+\\.[0-9]+\\.[0-9]+)$")
        message(WARNING "Simul version: tag '${tag}' is not v1.2.3 or 1.2.3, using 0.0.0")
        return()
    endif()
    set(${out_var} ${CMAKE_MATCH_1} PARENT_SCOPE)
endfunction()
