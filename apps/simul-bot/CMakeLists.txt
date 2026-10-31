add_executable(simul-bot
    src/main.cpp)

target_link_libraries(simul-bot PRIVATE simul::client)
target_compile_definitions(simul-bot PRIVATE
    SIMUL_VERSION="${PROJECT_VERSION}"
    SIMUL_BUILD_SHA="${SIMUL_BUILD_SHA}")
simul_set_warnings(simul-bot)
