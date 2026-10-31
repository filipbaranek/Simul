add_executable(simul-server
    src/main.cpp)

target_link_libraries(simul-server PRIVATE simul::server_core)
target_compile_definitions(simul-server PRIVATE
    SIMUL_VERSION="${PROJECT_VERSION}"
    SIMUL_BUILD_SHA="${SIMUL_BUILD_SHA}")
simul_set_warnings(simul-server)
