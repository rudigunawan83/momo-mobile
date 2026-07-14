namespace MomoAI.Domain.Entities;

/// <summary>
/// Represents Momo's personality profile for a specific user, defining behavior traits and tone.
/// </summary>
public record PersonalityProfile
{
    private static readonly HashSet<string> ValidTonePreferences = new(StringComparer.OrdinalIgnoreCase)
    {
        "playful",
        "supportive",
        "intellectual",
        "balanced"
    };

    public Guid UserId { get; init; }
    public double Humor { get; init; }
    public double Caring { get; init; }
    public double Curious { get; init; }
    public double Calm { get; init; }
    public string TonePreference { get; init; } = "balanced";
    public DateTime LastUpdated { get; init; }

    private PersonalityProfile() { }

    /// <summary>
    /// Creates a validated PersonalityProfile instance.
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when trait values are outside [0, 1].</exception>
    /// <exception cref="ArgumentException">Thrown when TonePreference is invalid.</exception>
    public static PersonalityProfile Create(
        Guid userId,
        double humor,
        double caring,
        double curious,
        double calm,
        string tonePreference,
        DateTime lastUpdated)
    {
        Validate(humor, caring, curious, calm, tonePreference);

        return new PersonalityProfile
        {
            UserId = userId,
            Humor = humor,
            Caring = caring,
            Curious = curious,
            Calm = calm,
            TonePreference = tonePreference,
            LastUpdated = lastUpdated
        };
    }

    /// <summary>
    /// Creates a default PersonalityProfile for a new user with all traits at 0.5 and balanced tone.
    /// </summary>
    public static PersonalityProfile CreateDefault(Guid userId)
    {
        return new PersonalityProfile
        {
            UserId = userId,
            Humor = 0.5,
            Caring = 0.5,
            Curious = 0.5,
            Calm = 0.5,
            TonePreference = "balanced",
            LastUpdated = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Checks whether the given tone preference is a valid value.
    /// </summary>
    public static bool IsValidTonePreference(string tone) => ValidTonePreferences.Contains(tone);

    private static void Validate(double humor, double caring, double curious, double calm, string tonePreference)
    {
        ValidateTraitBound(humor, nameof(humor));
        ValidateTraitBound(caring, nameof(caring));
        ValidateTraitBound(curious, nameof(curious));
        ValidateTraitBound(calm, nameof(calm));

        if (!IsValidTonePreference(tonePreference))
        {
            throw new ArgumentException(
                $"TonePreference must be one of: {string.Join(", ", ValidTonePreferences)}. Actual: '{tonePreference}'.",
                nameof(tonePreference));
        }
    }

    private static void ValidateTraitBound(double value, string paramName)
    {
        if (value < 0.0 || value > 1.0)
        {
            throw new ArgumentOutOfRangeException(paramName, value,
                $"{paramName} must be between 0.0 and 1.0 inclusive.");
        }
    }
}
