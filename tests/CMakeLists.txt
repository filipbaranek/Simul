add_executable(simul-tests
    smoke-test.cpp)

# Linking the libraries proves that a test binary can use them.
target_link_libraries(simul-tests PRIVATE Catch2::Catch2WithMain simul::common)
simul_set_warnings(simul-tests)

# Registers every TEST_CASE as its own CTest test; PRE_TEST runs the discovery when ctest starts
# instead of during the build.
list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
include(Catch)
catch_discover_tests(simul-tests DISCOVERY_MODE PRE_TEST)
