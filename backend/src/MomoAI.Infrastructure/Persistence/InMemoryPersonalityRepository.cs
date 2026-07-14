using System.Collections.Concurrent;
using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Persistence;

/// <summary>
/// In-memory implementation of IPersonalityRepository for development without a database.
/// </summary>
public class InMemoryPersonalityRepository : IPersonalityRepository
{
    private readonly ConcurrentDictionary<Guid, PersonalityProfile> _profiles = new();

    public PersonalityProfile? GetByUserId(Guid userId)
    {
        _profiles.TryGetValue(userId, out var profile);
        return profile;
    }

    public void Save(PersonalityProfile profile)
    {
        _profiles[profile.UserId] = profile;
    }
}
