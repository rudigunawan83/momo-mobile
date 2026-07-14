using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using MomoAI.API.Middleware;
using NSubstitute;

namespace MomoAI.API.Tests;

/// <summary>
/// Unit tests for SessionExpirationMiddleware.
/// Validates requirement 13.7: Session token expiration handling for HTTP requests.
/// </summary>
public class SessionExpirationMiddlewareTests
{
    private readonly ILogger<SessionExpirationMiddleware> _logger;
    private readonly RequestDelegate _next;

    public SessionExpirationMiddlewareTests()
    {
        _logger = Substitute.For<ILogger<SessionExpirationMiddleware>>();
        _next = Substitute.For<RequestDelegate>();
    }

    [Fact]
    public async Task InvokeAsync_WithValidToken_CallsNext()
    {
        // Token expires in 1 hour
        var expiration = DateTimeOffset.UtcNow.AddHours(1).ToUnixTimeSeconds();
        var context = CreateHttpContextWithExpClaim(expiration.ToString());

        var middleware = new SessionExpirationMiddleware(_next, _logger);
        await middleware.InvokeAsync(context);

        await _next.Received(1)(context);
    }

    [Fact]
    public async Task InvokeAsync_WithExpiredToken_Returns401()
    {
        // Token expired 1 hour ago
        var expiration = DateTimeOffset.UtcNow.AddHours(-1).ToUnixTimeSeconds();
        var context = CreateHttpContextWithExpClaim(expiration.ToString());

        var middleware = new SessionExpirationMiddleware(_next, _logger);
        await middleware.InvokeAsync(context);

        Assert.Equal(StatusCodes.Status401Unauthorized, context.Response.StatusCode);
        await _next.DidNotReceive()(context);
    }

    [Fact]
    public async Task InvokeAsync_WithExpiredToken_SetsWWWAuthenticateHeader()
    {
        var expiration = DateTimeOffset.UtcNow.AddHours(-1).ToUnixTimeSeconds();
        var context = CreateHttpContextWithExpClaim(expiration.ToString());

        var middleware = new SessionExpirationMiddleware(_next, _logger);
        await middleware.InvokeAsync(context);

        Assert.Contains("invalid_token", context.Response.Headers["WWW-Authenticate"].ToString());
    }

    [Fact]
    public async Task InvokeAsync_WithExpiredToken_WritesJsonErrorBody()
    {
        var expiration = DateTimeOffset.UtcNow.AddHours(-1).ToUnixTimeSeconds();
        var context = CreateHttpContextWithExpClaim(expiration.ToString());

        var middleware = new SessionExpirationMiddleware(_next, _logger);
        await middleware.InvokeAsync(context);

        context.Response.Body.Position = 0;
        using var reader = new StreamReader(context.Response.Body);
        var body = await reader.ReadToEndAsync();
        var json = JsonDocument.Parse(body);

        Assert.Equal("session_expired", json.RootElement.GetProperty("error").GetString());
    }

    [Fact]
    public async Task InvokeAsync_UnauthenticatedRequest_CallsNext()
    {
        // Anonymous user — middleware should not block
        var context = new DefaultHttpContext();

        var middleware = new SessionExpirationMiddleware(_next, _logger);
        await middleware.InvokeAsync(context);

        await _next.Received(1)(context);
    }

    [Fact]
    public async Task InvokeAsync_AuthenticatedWithoutExpClaim_CallsNext()
    {
        // Authenticated but no "exp" claim — treat as valid (let auth middleware handle)
        var identity = new ClaimsIdentity(new[]
        {
            new Claim("sub", Guid.NewGuid().ToString()),
        }, "TestAuth");
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(identity)
        };

        var middleware = new SessionExpirationMiddleware(_next, _logger);
        await middleware.InvokeAsync(context);

        await _next.Received(1)(context);
    }

    [Fact]
    public async Task InvokeAsync_ExpiredToken_DiscardsInFlightData()
    {
        // Requirement 13.7: discard any in-flight unsaved data from the expired session
        // This is validated by ensuring the pipeline does NOT continue (next is not called)
        var expiration = DateTimeOffset.UtcNow.AddSeconds(-10).ToUnixTimeSeconds();
        var context = CreateHttpContextWithExpClaim(expiration.ToString());

        var middleware = new SessionExpirationMiddleware(_next, _logger);
        await middleware.InvokeAsync(context);

        // Pipeline did not continue — in-flight request data is discarded
        await _next.DidNotReceive()(context);
    }

    private static DefaultHttpContext CreateHttpContextWithExpClaim(string expValue)
    {
        var identity = new ClaimsIdentity(new[]
        {
            new Claim("sub", Guid.NewGuid().ToString()),
            new Claim("exp", expValue),
        }, "TestAuth");

        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(identity)
        };

        // Use a memory stream so we can read the response body
        context.Response.Body = new MemoryStream();

        return context;
    }
}
