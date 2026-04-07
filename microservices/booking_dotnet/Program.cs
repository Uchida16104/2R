using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Npgsql;
using System.Text.Json;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

builder.Services.AddSingleton<NpgsqlDataSource>(sp =>
{
    var connStr = builder.Configuration["ConnectionStrings:Default"]
        ?? "Host=postgres;Database=reservations;Username=postgres;Password=secret";
    return NpgsqlDataSource.Create(connStr);
});

var app = builder.Build();
app.UseCors("AllowAll");

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "booking_dotnet" }));

app.MapGet("/calendar/{roomId}", async (string roomId, string date, NpgsqlDataSource db) =>
{
    await using var conn = await db.OpenConnectionAsync();
    await using var cmd  = conn.CreateCommand();

    cmd.CommandText = @"
        SELECT id, title, start_time, end_time, status
        FROM reservations
        WHERE room_id = $1
          AND DATE(start_time) = $2::date
          AND deleted_at IS NULL
        ORDER BY start_time";

    cmd.Parameters.AddWithValue(roomId);
    cmd.Parameters.AddWithValue(date);

    var results = new List<object>();
    await using var reader = await cmd.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        results.Add(new
        {
            id         = reader.GetInt64(0),
            title      = reader.GetString(1),
            start_time = reader.GetDateTime(2).ToString("o"),
            end_time   = reader.GetDateTime(3).ToString("o"),
            status     = reader.GetString(4),
        });
    }

    return Results.Ok(results);
});

app.MapPost("/enterprise/sync", async (HttpRequest request, NpgsqlDataSource db) =>
{
    using var body = await JsonDocument.ParseAsync(request.Body);
    var root = body.RootElement;

    if (!root.TryGetProperty("room_id",    out var roomIdEl)    ||
        !root.TryGetProperty("title",      out var titleEl)     ||
        !root.TryGetProperty("start_time", out var startEl)     ||
        !root.TryGetProperty("end_time",   out var endEl))
    {
        return Results.BadRequest(new { error = "Missing required fields" });
    }

    var roomId    = roomIdEl.GetString()!;
    var title     = titleEl.GetString()!;
    var startTime = DateTime.Parse(startEl.GetString()!);
    var endTime   = DateTime.Parse(endEl.GetString()!);

    await using var conn = await db.OpenConnectionAsync();
    await using var cmd  = conn.CreateCommand();

    cmd.CommandText = @"
        SELECT COUNT(*) FROM reservations
        WHERE room_id = $1
          AND status  = 'confirmed'
          AND deleted_at IS NULL
          AND start_time < $3
          AND end_time   > $2";

    cmd.Parameters.AddWithValue(roomId);
    cmd.Parameters.AddWithValue(startTime);
    cmd.Parameters.AddWithValue(endTime);

    var conflictCount = (long)(await cmd.ExecuteScalarAsync() ?? 0L);

    if (conflictCount > 0)
    {
        return Results.Conflict(new { error = "Time slot conflict detected by .NET enterprise layer" });
    }

    return Results.Ok(new { status = "cleared", room_id = roomId, title });
});

app.Run($"http://0.0.0.0:5001");
