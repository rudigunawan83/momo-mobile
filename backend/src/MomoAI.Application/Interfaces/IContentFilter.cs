namespace MomoAI.Application.Interfaces;

/// <summary>
/// Filters AI response content to detect and block inappropriate content
/// including violence, explicit material, hate speech, and PII.
/// </summary>
public interface IContentFilter
{
    /// <summary>
    /// Analyzes AI response content for policy violations.
    /// </summary>
    /// <param name="content">The AI-generated response to analyze.</param>
    /// <returns>A result indicating whether content was blocked and the violation categories.</returns>
    ContentFilterResult Filter(string content);
}

/// <summary>
/// Result of content filtering analysis.
/// </summary>
public record ContentFilterResult
{
    /// <summary>
    /// Whether the content was blocked by the filter.
    /// </summary>
    public bool IsBlocked { get; init; }

    /// <summary>
    /// Categories of violations detected (empty if not blocked).
    /// </summary>
    public IReadOnlyList<ContentViolationCategory> ViolationCategories { get; init; } = [];
}

/// <summary>
/// Categories of content policy violations.
/// </summary>
public enum ContentViolationCategory
{
    /// <summary>Content encouraging violence or self-harm.</summary>
    ViolenceOrSelfHarm,

    /// <summary>Sexually explicit material.</summary>
    SexuallyExplicit,

    /// <summary>Hate speech targeting protected groups.</summary>
    HateSpeech,

    /// <summary>Personally identifiable information (email, phone, SSN).</summary>
    PersonallyIdentifiableInformation
}
