using System.Data.Common;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging;

namespace MomoAI.Infrastructure.Persistence.Interceptors;

/// <summary>
/// EF Core DbConnection interceptor that sets the PostgreSQL session variable
/// 'app.current_user_id' when a connection is opened. This enables Row-Level Security
/// policies on the memories table to enforce per-user data isolation.
/// 
/// Satisfies requirement 13.3: Memory isolation via row-level security.
/// </summary>
public class RowLevelSecurityInterceptor : DbConnectionInterceptor
{
    private readonly ICurrentUserAccessor _currentUserAccessor;
    private readonly ILogger<RowLevelSecurityInterceptor> _logger;

    public RowLevelSecurityInterceptor(
        ICurrentUserAccessor currentUserAccessor,
        ILogger<RowLevelSecurityInterceptor> logger)
    {
        _currentUserAccessor = currentUserAccessor;
        _logger = logger;
    }

    public override async Task ConnectionOpenedAsync(
        DbConnection connection,
        ConnectionEndEventData eventData,
        CancellationToken cancellationToken = default)
    {
        await SetCurrentUserAsync(connection, cancellationToken);
        await base.ConnectionOpenedAsync(connection, eventData, cancellationToken);
    }

    public override void ConnectionOpened(
        DbConnection connection,
        ConnectionEndEventData eventData)
    {
        SetCurrentUser(connection);
        base.ConnectionOpened(connection, eventData);
    }

    private async Task SetCurrentUserAsync(DbConnection connection, CancellationToken ct)
    {
        var userId = _currentUserAccessor.UserId;
        if (userId == Guid.Empty)
        {
            _logger.LogDebug("No current user set — RLS session variable not applied.");
            return;
        }

        await using var command = connection.CreateCommand();
        command.CommandText = $"SET LOCAL app.current_user_id = '{userId}'";
        await command.ExecuteNonQueryAsync(ct);

        _logger.LogDebug("Set RLS session variable for user {UserId}", userId);
    }

    private void SetCurrentUser(DbConnection connection)
    {
        var userId = _currentUserAccessor.UserId;
        if (userId == Guid.Empty)
        {
            _logger.LogDebug("No current user set — RLS session variable not applied.");
            return;
        }

        using var command = connection.CreateCommand();
        command.CommandText = $"SET LOCAL app.current_user_id = '{userId}'";
        command.ExecuteNonQuery();

        _logger.LogDebug("Set RLS session variable for user {UserId}", userId);
    }
}

/// <summary>
/// Provides access to the current authenticated user's ID from the request context.
/// </summary>
public interface ICurrentUserAccessor
{
    /// <summary>
    /// Gets the current user's ID. Returns Guid.Empty if no user is authenticated.
    /// </summary>
    Guid UserId { get; }
}
