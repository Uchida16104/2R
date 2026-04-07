FROM ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y curl xz-utils && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz \
    | tar -xJ -C /usr/local --strip-components=1
WORKDIR /app
COPY . .
RUN zig build -Doptimize=ReleaseSafe

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/zig-out/bin/sys_zig ./
EXPOSE 9002
CMD ["./sys_zig"]
