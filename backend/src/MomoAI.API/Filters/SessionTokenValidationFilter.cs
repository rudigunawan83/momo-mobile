using Microsoft.AspNetCore.SignalR;
using MomoAI.Application.Interfaces;

namespace MomoAI.API.Filters;

/// <summary>
/// SignalR Hub filter that validates the session token on every hub method invocation.
/// When a session token expires or is invalidated:
/// - Terminates the active connection
/// - Requires re-authentication before processing further requests
/// - Discards any in-flight unsaved data from the expired session
/// 
/// Satisfies requirement 13.7.
/// </summary>
public class SessionTokenValidationFilter : IHubFilter
{
    private readonly ILogger<SessionTokenValidationFilter> _logger;

    public SessionTokenValidationFilter(ILogger<SessionTokenValidationFilter> logger)
    {
        _logger = logger;
    }

    public async ValueTask<object?> InvokeMethodAsync(
        HubInvocationContext invocationContext,
        Func<HubInvocationContext, ValueTask<object?>> next)
    {
        var httpContext = invocationContext.Context.GetHttpContext();
        if (httpContext is null)
        {
            // No HTTP context means this is likely a reconnection scenario — abort
            _logger.LogWarning("Hub invocation without HTTP context. ConnectionId: {ConnectionId}",
                invocationContext.Context.ConnectionId);
            invocationContext.Context.Abort();
            throw new HubException("Session expired. Please re-authenticate.");
        }

        // Validate the user's authentication claim
        var user = invocationContext.Context.User;
        if (user?.Identity?.IsAuthenticated != true)
        {
            _logger.LogWarning("Unauthenticated hub invocation detected. ConnectionId: {ConnectionId}",
                invocationContext.Context.ConnectionId);

            // Terminate the connection — discard in-flight data
            invocationContext.Context.Abort();
            throw new HubException("Session expired. Please re-authenticate.");
        }

        // Check token expiration claim
        var expClaim = user.FindFirst("exp");
        if (expClaim is not null && long.TryParse(expClaim.Value, out var expUnix))
        {
            var expiration = DateTimeOffset.FromUnixTimeSeconds(expUnix);
            if (expiration < DateTimeOffset.UtcNow)
            {
                _logger.LogInformation(
                    "Session token expired for user {UserId}. Terminating connection {ConnectionId}.",
                    user.FindFirst("sub")?.Value ?? "unknown",
                    invocationContext.Context.ConnectionId);

                // Terminate the active connection and discard in-flight data
                invocationContext.Context.Abort();
                throw new HubException("Session token expired. Please re-authenticate.");
            }
        }

        // Token is valid — proceed with the hub method
        return await next(invocationContext);
    }
}
