using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<IUserService, UserService>();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();

// Minimal API endpoints
app.MapGet("/", () => "Hello World!");

app.MapGet("/health", () => new { status = "healthy", timestamp = DateTime.UtcNow });

app.MapPost("/api/minimal/users", (CreateUserRequest request) => 
{
    // Create user logic
    return Results.Created($"/api/users/{Guid.NewGuid()}", new { id = Guid.NewGuid(), name = request.Name });
});

app.MapPut("/api/minimal/users/{id:guid}", (Guid id, UpdateUserRequest request) =>
{
    // Update user logic
    return Results.Ok(new { id, name = request.Name, updated = DateTime.UtcNow });
});

app.MapDelete("/api/minimal/users/{id:guid}", (Guid id) =>
{
    // Delete user logic
    return Results.NoContent();
});

// Map endpoints using endpoint routing
app.UseRouting();
app.UseEndpoints(endpoints =>
{
    endpoints.MapGet("/api/endpoints/status", async context =>
    {
        await context.Response.WriteAsync("Endpoints are working!");
    });
    
    endpoints.MapPost("/api/endpoints/webhook", async context =>
    {
        // Webhook handling logic
        await context.Response.WriteAsync("Webhook received");
    });
});

app.MapControllers();

app.Run();

public record CreateUserRequest(string Name, string Email);
public record UpdateUserRequest(string Name, string Email);