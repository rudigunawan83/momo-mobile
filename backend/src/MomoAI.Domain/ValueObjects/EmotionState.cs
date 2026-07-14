namespace MomoAI.Domain.ValueObjects;

using MomoAI.Domain.Enums;

/// <summary>
/// Value object representing Momo's emotional state with validated bounds.
/// </summary>
public record EmotionState
{
    public EmotionType Primary { get; init; }
    public EmotionType? Secondary { get; init; }
    public double Intensity { get; init; }
    public double Valence { get; init; }
    public double Arousal { get; init; }
    public DateTime Timestamp { get; init; }

    private EmotionState() { }

    /// <summary>
    /// Creates a validated EmotionState instance.
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when values are outside valid bounds.</exception>
    public static EmotionState Create(
        EmotionType primary,
        double intensity,
        double valence,
        double arousal,
        DateTime timestamp,
        EmotionType? secondary = null)
    {
        Validate(intensity, valence, arousal);

        return new EmotionState
        {
            Primary = primary,
            Secondary = secondary,
            Intensity = intensity,
            Valence = valence,
            Arousal = arousal,
            Timestamp = timestamp
        };
    }

    private static void Validate(double intensity, double valence, double arousal)
    {
        if (intensity < 0.0 || intensity > 1.0)
        {
            throw new ArgumentOutOfRangeException(nameof(intensity), intensity,
                "Intensity must be between 0.0 and 1.0 inclusive.");
        }

        if (valence < -1.0 || valence > 1.0)
        {
            throw new ArgumentOutOfRangeException(nameof(valence), valence,
                "Valence must be between -1.0 and 1.0 inclusive.");
        }

        if (arousal < 0.0 || arousal > 1.0)
        {
            throw new ArgumentOutOfRangeException(nameof(arousal), arousal,
                "Arousal must be between 0.0 and 1.0 inclusive.");
        }
    }
}
