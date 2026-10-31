#include <iostream>
#include <string_view>

// Placeholder: only reports its version until the real bot exists.
int main(int argc, char* argv[])
{
    if (argc > 1 && std::string_view{argv[1]} == "--version") {
        std::cout << "simul-bot " << SIMUL_VERSION << " (" << SIMUL_BUILD_SHA << ")\n";
    }
    return 0;
}
