# Dockerfile for VirtualTM
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    valac \
    meson \
    ninja-build \
    libglib2.0-dev \
    libjson-glib-dev \
    libsoup-3.0-dev \
    libsqlite3-dev \
    dbus \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build the project
RUN meson setup build && ninja -C build

# Expose port
EXPOSE 8999

# Start D-Bus and run server
CMD ["sh", "-c", "dbus-daemon --session --fork && ./build/src/virtualtm-server"]