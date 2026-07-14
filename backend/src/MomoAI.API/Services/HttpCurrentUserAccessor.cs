using System.Security.Claims;
using MomoAI.Infrastructure.Persistence.Interceptors;

namespace MomoAI.API.Services;

/// <summary>
/// Extracts the current user ID from the HTTP context claims.
/// Used by the RowLevelSecurityInterceptor to set the PostgreSQL session variable.
/// </summary>
public class HttpCurrentUserAccessor : ICurrentUserAccessor
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public HttpCurrentUserAccessor(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public Guid UserId
    {
        get
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user?.Identity?.IsAuthenticated != true)
                return Guid.Empty;

            var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? user.FindFirst("sub")?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
                return Guid.Empty;

            return userId;
        }
    }
}
