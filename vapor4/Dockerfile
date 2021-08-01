# syntax=docker/dockerfile:experimental
# ================================
# Build image
# ================================
# Pin an exact toolchain version by image hash
# Toolchain Tag: swift-5.5-DEVELOPMENT-SNAPSHOT-2021-07-30-a
# FROM swiftlang/swift:nightly-5.5-bionic as build
FROM swiftlang/swift@sha256:da660befd5145760a5f7134920248eb54e6f283c1318c8ae22b3069a6b5f169f as build
ENV QEMU_SET_ENV=QEMU_CPU=max

# Install OS updates and, if needed, sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install libssl-dev -y \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build everything, with optimizations and test discovery
RUN --mount=type=cache,target=/build/.build \
  swift build -Xswiftc -g -j 1 -v

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN --mount=type=cache,target=/build/.build \
  cp "$(swift build --package-path /build --show-bin-path)/Run" ./

# Let Docker bind to port 8080
EXPOSE 8080
ENTRYPOINT ["/staging/Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
