FROM gcc:13-bookworm AS builder
WORKDIR /app
COPY slot_resolver.cpp ./
RUN g++ -std=c++20 -O3 -pthread -o slot_resolver slot_resolver.cpp

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/slot_resolver ./
EXPOSE 9001
CMD ["./slot_resolver"]
