add_library(simul-client STATIC
    src/placeholder.cpp)
add_library(simul::client ALIAS simul-client)

target_include_directories(simul-client PUBLIC include)
target_compile_features(simul-client PUBLIC cxx_std_20)
# simul::net is PRIVATE: the public API uses pimpl, so the host application never sees Asio headers.
target_link_libraries(simul-client
    PUBLIC  simul::protocol simul::common
    PRIVATE simul::net)
simul_set_warnings(simul-client)
