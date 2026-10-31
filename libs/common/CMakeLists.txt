add_library(simul-common STATIC
    src/placeholder.cpp)
add_library(simul::common ALIAS simul-common)

target_include_directories(simul-common PUBLIC include)
target_compile_features(simul-common PUBLIC cxx_std_20)
target_link_libraries(simul-common PUBLIC spdlog::spdlog)
simul_set_warnings(simul-common)
