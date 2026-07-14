using MomoAI.Application.DTOs;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Defines and applies Momo's personality traits to AI responses,
/// ensuring consistent character behavior across conversations.
/// </summary>
public interface IPersonalityEngine
{
    /// <summary>
    /// Gets the personality profile for a user. Returns default profile (all traits 0.5, tone "balanced")
    /// if no profile exists yet.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <returns>The user's personality profile.</returns>
    PersonalityProfile GetProfile(Guid userId);

    /// <summary>
    /// Applies personality trait weights and tone preference to a base prompt,
    /// generating a system prompt that includes tone and behavior instructions.
    /// </summary>
    /// <param name="basePrompt">The base system prompt template.</param>
    /// <param name="profile">The personality profile to apply.</param>
    /// <returns>A modified prompt string incorporating personality instructions.</returns>
    string ApplyPersonalityToPrompt(string basePrompt, PersonalityProfile profile);

    /// <summary>
    /// Adjusts personality traits based on user feedback. Each trait is adjusted by
    /// no more than ±0.1 per feedback event, and all values remain clamped to [0.0, 1.0].
    /// Invalid tone preferences are rejected (existing tone is retained).
    /// </summary>
    /// <param name="current">The current personality profile.</param>
    /// <param name="feedback">The user feedback to apply.</param>
    /// <returns>The adjusted personality profile.</returns>
    PersonalityProfile AdjustFromFeedback(PersonalityProfile current, UserFeedback feedback);
}
