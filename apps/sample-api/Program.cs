var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

var app = builder.Build();

// Version is managed by Release Please in SampleApi.csproj
var version = typeof(Program).Assembly.GetName().Version?.ToString(3) ?? "unknown";

app.MapGet("/", () => Results.Ok(new
{
    name = "Sample API",
    version,
    status = "running"
}));

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.MapHealthChecks("/health/ready");

app.Run();

// Required for WebApplicationFactory in integration tests
public partial class Program { }
