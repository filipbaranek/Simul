add_library(simul-net STATIC
    src/placeholder.cpp)
add_library(simul::net ALIAS simul-net)

target_include_directories(simul-net PUBLIC include)
target_compile_features(simul-net PUBLIC cxx_std_20)
target_link_libraries(simul-net PUBLIC simul::protocol simul::common asio::asio)
simul_set_warnings(simul-net)
