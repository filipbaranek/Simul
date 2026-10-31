# Pure library: messages, serialisation and framing, no sockets.
add_library(simul-protocol STATIC
    src/placeholder.cpp)
add_library(simul::protocol ALIAS simul-protocol)

target_include_directories(simul-protocol PUBLIC include)
target_compile_features(simul-protocol PUBLIC cxx_std_20)
simul_set_warnings(simul-protocol)
