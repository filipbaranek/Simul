#include <asio/co_spawn.hpp>
#include <asio/detached.hpp>
#include <asio/io_context.hpp>
#include <asio/ip/tcp.hpp>
#include <asio/signal_set.hpp>
#include <asio/use_awaitable.hpp>

#include <csignal>
#include <iostream>
#include <string_view>

// Placeholder until the real server exists: accepts connections and closes them right away, so the
// container and deploy checks have something to connect to.
namespace {

constexpr asio::ip::port_type port = 7777;

asio::awaitable<void> accept_connections(asio::ip::tcp::acceptor& acceptor)
{
    for (;;) {
        co_await acceptor.async_accept(asio::use_awaitable);
    }
}

} // namespace

int main(int argc, char* argv[])
{
    if (argc > 1 && std::string_view{argv[1]} == "--version") {
        std::cout << "simul-server " << SIMUL_VERSION << " (" << SIMUL_BUILD_SHA << ")\n";
        return 0;
    }

    asio::io_context io;
    asio::ip::tcp::acceptor acceptor{io, {asio::ip::tcp::v4(), port}};

    asio::signal_set signals{io, SIGINT, SIGTERM};
    signals.async_wait([&io](const std::error_code&, int) { io.stop(); });

    asio::co_spawn(io, accept_connections(acceptor), asio::detached);

    // std::endl flushes: stdout is a pipe in a container, so it would otherwise stay buffered.
    std::cout << "simul-server " << SIMUL_VERSION << " (" << SIMUL_BUILD_SHA << ") listening on port "
              << port << std::endl;
    io.run();
    std::cout << "simul-server stopped" << std::endl;
}
