#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <thread>
#include <mutex>
#include <atomic>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

struct Slot {
    int64_t start_epoch;
    int64_t end_epoch;
    char    room_id[64];
};

static std::vector<Slot>  g_slots;
static std::mutex         g_mutex;
static std::atomic<bool>  g_running{true};

bool overlaps(const Slot& a, const Slot& b) {
    return std::strcmp(a.room_id, b.room_id) == 0
        && a.start_epoch < b.end_epoch
        && a.end_epoch   > b.start_epoch;
}

bool has_conflict(const Slot& candidate) {
    std::lock_guard<std::mutex> lock(g_mutex);
    for (const auto& s : g_slots) {
        if (overlaps(s, candidate)) return true;
    }
    return false;
}

void add_slot(const Slot& s) {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_slots.push_back(s);
}

std::string build_response(int status, const std::string& body) {
    std::string status_line = (status == 200)
        ? "HTTP/1.1 200 OK\r\n"
        : "HTTP/1.1 409 Conflict\r\n";
    return status_line
        + "Content-Type: application/json\r\n"
        + "Access-Control-Allow-Origin: *\r\n"
        + "Content-Length: " + std::to_string(body.size()) + "\r\n"
        + "\r\n"
        + body;
}

std::string extract_json_string(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\":\"";
    auto pos = json.find(search);
    if (pos == std::string::npos) return "";
    pos += search.size();
    auto end = json.find('"', pos);
    if (end == std::string::npos) return "";
    return json.substr(pos, end - pos);
}

int64_t iso_to_epoch(const std::string& iso) {
    if (iso.empty()) return 0;
    struct tm t{};
    sscanf(iso.c_str(), "%d-%d-%dT%d:%d:%d",
           &t.tm_year, &t.tm_mon, &t.tm_mday,
           &t.tm_hour, &t.tm_min, &t.tm_sec);
    t.tm_year -= 1900;
    t.tm_mon  -= 1;
    return static_cast<int64_t>(timegm(&t));
}

void handle_client(int client_fd) {
    char buf[4096] = {};
    ssize_t n = recv(client_fd, buf, sizeof(buf) - 1, 0);
    if (n <= 0) { close(client_fd); return; }

    std::string request(buf, n);

    if (request.find("GET /health") != std::string::npos) {
        std::string resp = build_response(200, R"({"status":"ok","service":"perf_cpp"})");
        send(client_fd, resp.c_str(), resp.size(), 0);
        close(client_fd);
        return;
    }

    if (request.find("POST /resolve") != std::string::npos) {
        auto body_pos = request.find("\r\n\r\n");
        std::string body = (body_pos != std::string::npos)
            ? request.substr(body_pos + 4) : "";

        std::string room_id    = extract_json_string(body, "room_id");
        std::string start_str  = extract_json_string(body, "start_time");
        std::string end_str    = extract_json_string(body, "end_time");

        Slot candidate{};
        candidate.start_epoch = iso_to_epoch(start_str);
        candidate.end_epoch   = iso_to_epoch(end_str);
        std::strncpy(candidate.room_id, room_id.c_str(), 63);

        if (candidate.start_epoch <= 0 || candidate.end_epoch <= candidate.start_epoch) {
            std::string resp = build_response(409, R"({"conflict":true,"reason":"Invalid time range"})");
            send(client_fd, resp.c_str(), resp.size(), 0);
            close(client_fd);
            return;
        }

        bool conflict = has_conflict(candidate);
        std::string resp_body = conflict
            ? R"({"conflict":true,"reason":"Slot overlap detected"})"
            : R"({"conflict":false})";

        if (!conflict) add_slot(candidate);

        std::string resp = build_response(conflict ? 409 : 200, resp_body);
        send(client_fd, resp.c_str(), resp.size(), 0);
        close(client_fd);
        return;
    }

    std::string resp = build_response(200, R"({"error":"unknown route"})");
    send(client_fd, resp.c_str(), resp.size(), 0);
    close(client_fd);
}

int main() {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) { perror("socket"); return 1; }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    sockaddr_in addr{};
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons(9001);

    if (bind(server_fd, (sockaddr*)&addr, sizeof(addr)) < 0) { perror("bind"); return 1; }
    if (listen(server_fd, 128) < 0) { perror("listen"); return 1; }

    std::cout << "perf_cpp slot resolver listening on :9001\n" << std::flush;

    while (g_running) {
        sockaddr_in client_addr{};
        socklen_t client_len = sizeof(client_addr);
        int client_fd = accept(server_fd, (sockaddr*)&client_addr, &client_len);
        if (client_fd < 0) continue;

        std::thread(handle_client, client_fd).detach();
    }

    close(server_fd);
    return 0;
}
