using MomoAI.Application.DTOs;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Repository interface for personality profile persistence.
/// </summary>
public interface IPersonalityRepository
{
    /// <summary>
    /// Retrieves a personality profile by user ID.
    /// Returns null if no profile exists for the user.
    /// </summary>
    PersonalityProfile? GetByUserId(Guid userId);

    /// <summary>
    /// Saves or updates a personality profile.
    /// </summary>
    void Save(PersonalityProfile profile);
}
