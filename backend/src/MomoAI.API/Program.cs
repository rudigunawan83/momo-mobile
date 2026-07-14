using System.Security.Authentication;
using Microsoft.AspNetCore.SignalR;
using MomoAI.API.Filters;
using MomoAI.API.Hubs;
using MomoAI.API.Middleware;
using MomoAI.API.Services;
using MomoAI.Application;
using MomoAI.Application.Interfaces;
using MomoAI.Infrastructure;
using MomoAI.Infrastructure.Persistence.Interceptors;

var builder = WebApplication.CreateBuilder(args);

// Configure TLS 1.3 for all data in transit (Req 13.1)
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.ConfigureHttpsDefaults(httpsOptions =>
    {
        httpsOptions.SslProtocols = SslProtocols.Tls13;
    });
});

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpContextAccessor();

// Register SignalR with configuration for real-time streaming and session validation
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = builder.Environment.IsDevelopment();
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
    options.MaximumReceiveMessageSize = 64 * 1024; // 64KB max message
});

// Register hub notification service for pushing updates from backend services
builder.Services.AddScoped<IHubNotificationService, HubNotificationService>();

// Register session token validation filter for SignalR hub methods (Req 13.7)
builder.Services.AddSingleton<IHubFilter, SessionTokenValidationFilter>();

// Register ICurrentUserAccessor for Row-Level Security (Req 13.3)
builder.Services.AddScoped<ICurrentUserAccessor, HttpCurrentUserAccessor>();

// Register Clean Architecture layers
builder.Services.AddApplication();
builder.Services.AddInfrastructure(
    connectionString: builder.Configuration.GetConnectionString("DefaultConnection"),
    configuration: builder.Configuration);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();

// Validate session token expiration for HTTP requests (Req 13.7)
app.UseSessionExpiration();

app.UseAuthorization();
app.MapControllers();

// Map the SignalR ChatHub at /hubs/chat
app.MapHub<ChatHub>("/hubs/chat");

app.Run();
