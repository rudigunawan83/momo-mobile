using System.Text;
using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Implements personality engine logic: profile retrieval/creation, prompt modification,
/// and feedback-based trait adjustment.
/// </summary>
public class PersonalityEngine : IPersonalityEngine
{
    private static readonly HashSet<string> ValidTonePreferences = new(StringComparer.OrdinalIgnoreCase)
    {
        "playful",
        "supportive",
        "intellectual",
        "balanced"
    };

    private const double MaxAdjustmentPerTrait = 0.1;
    private const double DefaultTraitValue = 0.5;
    private const string DefaultTone = "balanced";

    private readonly IPersonalityRepository _repository;

    public PersonalityEngine(IPersonalityRepository repository)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
    }

    /// <inheritdoc />
    public PersonalityProfile GetProfile(Guid userId)
    {
        var existing = _repository.GetByUserId(userId);
        if (existing is not null)
            return existing;

        var defaultProfile = CreateDefaultProfile(userId);
        _repository.Save(defaultProfile);
        return defaultProfile;
    }

    /// <inheritdoc />
    public string ApplyPersonalityToPrompt(string basePrompt, PersonalityProfile profile)
    {
        var sb = new StringBuilder(basePrompt);
        sb.AppendLine();
        sb.AppendLine();
        sb.AppendLine("## Personality Instructions");

        // Tone preference instruction
        sb.AppendLine($"- Overall tone: {GetToneInstruction(profile.TonePreference)}");

        // Trait-based behavior instructions
        sb.AppendLine(GetHumorInstruction(profile.Humor));
        sb.AppendLine(GetCaringInstruction(profile.Caring));
        sb.AppendLine(GetCuriousInstruction(profile.Curious));
        sb.AppendLine(GetCalmInstruction(profile.Calm));

        return sb.ToString();
    }

    /// <inheritdoc />
    public PersonalityProfile AdjustFromFeedback(PersonalityProfile current, UserFeedback feedback)
    {
        var humor = current.Humor;
        var caring = current.Caring;
        var curious = current.Curious;
        var calm = current.Calm;
        var tone = current.TonePreference;

        // Determine adjustment direction from sentiment
        // Positive sentiment means "more of this", negative means "less of this"
        var adjustment = ClampAdjustment(feedback.Sentiment);

        // Apply adjustment to targeted trait
        if (!string.IsNullOrWhiteSpace(feedback.TargetTrait))
        {
            switch (feedback.TargetTrait.ToLowerInvariant())
            {
                case "humor":
                    humor = ClampTrait(humor + adjustment);
                    break;
                case "caring":
                    caring = ClampTrait(caring + adjustment);
                    break;
                case "curious":
                    curious = ClampTrait(curious + adjustment);
                    break;
                case "calm":
                    calm = ClampTrait(calm + adjustment);
                    break;
            }
        }

        // Handle tone preference from feedback type
        if (feedback.FeedbackType.Equals("tone_change", StringComparison.OrdinalIgnoreCase))
        {
            // Only update tone if the target trait field contains a valid tone preference
            if (feedback.TargetTrait is not null && IsValidTonePreference(feedback.TargetTrait))
            {
                tone = feedback.TargetTrait.ToLowerInvariant();
            }
            // If invalid, retain existing tone (do nothing)
        }

        return new PersonalityProfile
        {
            UserId = current.UserId,
            Humor = humor,
            Caring = caring,
            Curious = curious,
            Calm = calm,
            TonePreference = tone,
            LastUpdated = DateTime.UtcNow
        };
    }

    private static PersonalityProfile CreateDefaultProfile(Guid userId)
    {
        return new PersonalityProfile
        {
            UserId = userId,
            Humor = DefaultTraitValue,
            Caring = DefaultTraitValue,
            Curious = DefaultTraitValue,
            Calm = DefaultTraitValue,
            TonePreference = DefaultTone,
            LastUpdated = DateTime.UtcNow
        };
    }

    private static bool IsValidTonePreference(string tone)
    {
        return ValidTonePreferences.Contains(tone);
    }

    /// <summary>
    /// Clamps the adjustment value to ±0.1 range.
    /// </summary>
    private static double ClampAdjustment(double value)
    {
        return Math.Clamp(value, -MaxAdjustmentPerTrait, MaxAdjustmentPerTrait);
    }

    /// <summary>
    /// Clamps a trait value to [0.0, 1.0].
    /// </summary>
    private static double ClampTrait(double value)
    {
        return Math.Clamp(value, 0.0, 1.0);
    }

    private static string GetToneInstruction(string tone)
    {
        return tone.ToLowerInvariant() switch
        {
            "playful" => "Be playful, lighthearted, and fun. Use casual language and humor.",
            "supportive" => "Be warm, encouraging, and emotionally supportive. Prioritize empathy.",
            "intellectual" => "Be thoughtful, analytical, and curious. Engage with ideas deeply.",
            "balanced" => "Maintain a balanced tone between warmth, humor, and thoughtfulness.",
            _ => "Maintain a balanced tone between warmth, humor, and thoughtfulness."
        };
    }

    private static string GetHumorInstruction(double humor)
    {
        return humor switch
        {
            >= 0.8 => "- Be playful and use humor frequently. Add jokes, puns, and witty remarks.",
            >= 0.6 => "- Include light humor and playful comments when appropriate.",
            >= 0.4 => "- Use humor sparingly and keep a balanced conversational tone.",
            >= 0.2 => "- Keep responses mostly serious with occasional light moments.",
            _ => "- Maintain a serious and straightforward tone. Avoid humor."
        };
    }

    private static string GetCaringInstruction(double caring)
    {
        return caring switch
        {
            >= 0.8 => "- Show deep warmth and empathy. Be nurturing and emotionally attentive.",
            >= 0.6 => "- Be warm and caring. Show genuine concern for the user's feelings.",
            >= 0.4 => "- Be friendly and considerate in a balanced way.",
            >= 0.2 => "- Be polite but keep emotional engagement moderate.",
            _ => "- Keep responses focused on facts rather than emotions."
        };
    }

    private static string GetCuriousInstruction(double curious)
    {
        return curious switch
        {
            >= 0.8 => "- Be highly inquisitive. Ask follow-up questions and explore topics enthusiastically.",
            >= 0.6 => "- Show curiosity about the user's interests. Ask relevant questions.",
            >= 0.4 => "- Be receptive and engage with topics the user brings up.",
            >= 0.2 => "- Respond to what's asked without probing too deeply.",
            _ => "- Focus on answering directly without additional questioning."
        };
    }

    private static string GetCalmInstruction(double calm)
    {
        return calm switch
        {
            >= 0.8 => "- Be serene and composed. Use a gentle, measured pace in responses.",
            >= 0.6 => "- Maintain a calm and steady presence. Be reassuring.",
            >= 0.4 => "- Balance between energetic and calm depending on context.",
            >= 0.2 => "- Be more energetic and expressive in responses.",
            _ => "- Be highly energetic, enthusiastic, and animated in tone."
        };
    }
}
