using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MomoAI.Application.Interfaces;
using MomoAI.Infrastructure.Persistence;
using MomoAI.Infrastructure.Persistence.Interceptors;
using MomoAI.Infrastructure.Services;

namespace MomoAI.Infrastructure;

/// <summary>
/// Extension methods for registering Infrastructure layer services in the DI container.
/// </summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, string? connectionString = null, IConfiguration? configuration = null)
    {
        // Register the RLS interceptor (scoped — depends on ICurrentUserAccessor)
        services.AddScoped<RowLevelSecurityInterceptor>();

        // Register DbContext with pgvector support and RLS interceptor
        if (!string.IsNullOrEmpty(connectionString))
        {
            services.AddDbContext<MomoDbContext>((serviceProvider, options) =>
            {
                options.UseNpgsql(connectionString, npgsqlOptions =>
                    npgsqlOptions.UseVector());

                // Add RLS interceptor to set session user on connection open
                var rlsInterceptor = serviceProvider.GetRequiredService<RowLevelSecurityInterceptor>();
                options.AddInterceptors(rlsInterceptor);
            });
        }
        else
        {
            // Fallback: InMemory database for development without PostgreSQL
            services.AddDbContext<MomoDbContext>(options =>
                options.UseInMemoryDatabase("MomoAI_Dev"));
        }

        // AI Gateway
        if (configuration is not null)
        {
            services.Configure<AIGatewayOptions>(configuration.GetSection(AIGatewayOptions.SectionName));
            services.Configure<EncryptionOptions>(configuration.GetSection(EncryptionOptions.SectionName));
        }
        services.AddScoped<IAIGateway, AIGateway>();

        // Repositories (in-memory implementations for dev; swap with EF-backed for production)
        services.AddSingleton<IPersonalityRepository, InMemoryPersonalityRepository>();
        services.AddSingleton<IFriendshipRepository, InMemoryFriendshipRepository>();
        services.AddSingleton<IChatMessageRepository, InMemoryChatMessageRepository>();

        // Embedding Service (fake for dev without OpenAI embeddings API)
        services.AddSingleton<IEmbeddingService, FakeEmbeddingService>();

        // Personality Engine
        services.AddScoped<IPersonalityEngine, PersonalityEngine>();

        // Memory Engine
        services.AddScoped<IMemoryEngine, MemoryEngine>();

        // Friendship Service
        services.AddScoped<IFriendshipService, FriendshipService>();

        // Security: AES-256 Encryption for memories at rest (Req 13.2)
        services.AddSingleton<IEncryptionService, AesEncryptionService>();

        // Security: Prompt Injection Detection & Content Filtering
        services.AddSingleton<IPromptInjectionDetector, PromptInjectionDetector>();
        services.AddSingleton<IContentFilter, ContentFilter>();

        // Rate Limiting
        services.AddSingleton<TimeProvider>(TimeProvider.System);
        services.AddSingleton<IRateLimiter, InMemoryRateLimiter>();

        // Chat Service
        services.AddScoped<IChatService, ChatService>();

        return services;
    }
}
