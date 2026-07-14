using Microsoft.Extensions.DependencyInjection;

namespace MomoAI.Application;

/// <summary>
/// Extension methods for registering Application layer services in the DI container.
/// </summary>
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        // Application-level services (use cases, handlers) will be registered here
        // as they are implemented in subsequent tasks.
        return services;
    }
}
