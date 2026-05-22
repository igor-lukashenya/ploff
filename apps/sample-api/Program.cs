var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new
{
    name = "Sample API",
    version = "1.0.0",
    status = "running"
}));

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.MapHealthChecks("/health/ready");

app.Run();

// Required for WebApplicationFactory in integration tests
public partial class Program { }
