using Microsoft.EntityFrameworkCore;
using XWifiApi.Data;
using XWifiApi.Models;
using XWifiApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<XWifiDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<WiFiNetworkService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();

var apiGroup = app.MapGroup("/api");

apiGroup.MapGet("/networks", async (WiFiNetworkService service) =>
{
    return Results.Ok(await service.GetAllAsync());
});

apiGroup.MapGet("/networks/{id}", async (string id, WiFiNetworkService service) =>
{
    var network = await service.GetByIdAsync(id);
    if (network == null)
    {
        return Results.NotFound();
    }
    return Results.Ok(network);
});

apiGroup.MapPost("/networks", async (WiFiNetwork network, WiFiNetworkService service) =>
{
    var result = await service.AddAsync(network);
    return Results.Created($"/api/networks/{result.Id}", result);
});

apiGroup.MapDelete("/networks/{id}", async (string id, WiFiNetworkService service) =>
{
    var result = await service.DeleteAsync(id);
    if (!result)
    {
        return Results.NotFound();
    }
    return Results.NoContent();
});

app.MapGet("/", () => "XWifi API is running!");

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<XWifiDbContext>();
    dbContext.Database.EnsureCreated();
}

app.Run();