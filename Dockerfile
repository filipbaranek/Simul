FROM docker.io/library/debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS build

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends g++ cmake ninja-build git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

# The build context has no .git, so the version and commit come from CI.
ARG SIMUL_VERSION=
ARG SIMUL_BUILD_SHA=unknown

RUN cmake --preset release \
        -DSIMUL_BUILD_TESTS=OFF \
        -DSIMUL_VERSION=${SIMUL_VERSION} \
        -DSIMUL_BUILD_SHA=${SIMUL_BUILD_SHA} \
    && cmake --build --preset release --target simul-server

# Same Debian release as the build stage, so the glibc and libstdc++ the binary needs are present.
FROM docker.io/library/debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4

RUN useradd --uid 10001 --user-group --no-create-home --shell /usr/sbin/nologin simul \
    && install -d -o simul -g simul /var/lib/simul

COPY --from=build /src/build/release/apps/simul-server/simul-server /usr/local/bin/simul-server

USER 10001:10001
EXPOSE 7777
ENTRYPOINT ["/usr/local/bin/simul-server"]
