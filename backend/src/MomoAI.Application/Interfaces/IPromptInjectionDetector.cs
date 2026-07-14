namespace MomoAI.Application.Interfaces;

/// <summary>
/// Detects prompt injection attempts in user messages.
/// Checks for system instruction overrides, role impersonation,
/// and delimiter escape sequences.
/// </summary>
public interface IPromptInjectionDetector
{
    /// <summary>
    /// Analyzes a user message for prompt injection patterns.
    /// </summary>
    /// <param name="message">The user message to analyze.</param>
    /// <returns>A result indicating whether injection was detected and the category.</returns>
    PromptInjectionResult Detect(string message);
}

/// <summary>
/// Result of prompt injection detection analysis.
/// </summary>
public record PromptInjectionResult
{
    /// <summary>
    /// Whether a prompt injection attempt was detected.
    /// </summary>
    public bool IsInjectionDetected { get; init; }

    /// <summary>
    /// Category of the detected injection (null if not detected).
    /// </summary>
    public PromptInjectionCategory? Category { get; init; }
}

/// <summary>
/// Categories of prompt injection attacks.
/// </summary>
public enum PromptInjectionCategory
{
    /// <summary>Attempts to override system instructions (e.g., "ignore previous instructions").</summary>
    SystemInstructionOverride,

    /// <summary>Attempts to impersonate a different role (e.g., "you are now", "act as").</summary>
    RoleImpersonation,

    /// <summary>Attempts to escape context delimiters (e.g., ```system, [SYSTEM]).</summary>
    DelimiterEscape
}
