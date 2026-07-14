namespace MomoAI.API.Middleware;

/// <summary>
/// Middleware that validates session token expiration for authenticated HTTP requests.
/// When a token is expired, returns 401 requiring re-authentication.
/// Works alongside the SignalR SessionTokenValidationFilter for WebSocket connections.
/// 
/// Satisfies requirement 13.7 for HTTP API endpoints.
/// </summary>
public class SessionExpirationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<SessionExpirationMiddleware> _logger;

    public SessionExpirationMiddleware(RequestDelegate next, ILogger<SessionExpirationMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Only check authenticated requests
        if (context.User?.Identity?.IsAuthenticated == true)
        {
            var expClaim = context.User.FindFirst("exp");
            if (expClaim is not null && long.TryParse(expClaim.Value, out var expUnix))
            {
                var expiration = DateTimeOffset.FromUnixTimeSeconds(expUnix);
                if (expiration < DateTimeOffset.UtcNow)
                {
                    _logger.LogInformation(
                        "Expired session token detected for user {UserId}. Requiring re-authentication.",
                        context.User.FindFirst("sub")?.Value ?? "unknown");

                    context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    context.Response.Headers.Append("WWW-Authenticate", "Bearer error=\"invalid_token\", error_description=\"Token has expired\"");

                    await context.Response.WriteAsJsonAsync(new
                    {
                        error = "session_expired",
                        message = "Session token has expired. Please re-authenticate.",
                        code = 401
                    });

                    return; // Do not continue pipeline — discard in-flight request
                }
            }
        }

        await _next(context);
    }
}

/// <summary>
/// Extension methods for registering the SessionExpirationMiddleware.
/// </summary>
public static class SessionExpirationMiddlewareExtensions
{
    public static IApplicationBuilder UseSessionExpiration(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<SessionExpirationMiddleware>();
    }
}
