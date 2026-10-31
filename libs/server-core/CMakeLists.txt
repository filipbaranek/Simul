# A library rather than part of simul-server, so it can be embedded later (LAN mode).
add_library(simul-server-core STATIC
    src/placeholder.cpp)
add_library(simul::server_core ALIAS simul-server-core)

target_include_directories(simul-server-core PUBLIC include)
target_compile_features(simul-server-core PUBLIC cxx_std_20)
target_link_libraries(simul-server-core PUBLIC simul::net simul::common)
simul_set_warnings(simul-server-core)
