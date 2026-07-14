using System.Text.RegularExpressions;
using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Content filter for AI responses. Detects violence/self-harm encouragement,
/// sexually explicit material, hate speech, and PII in generated content.
/// Uses regex patterns and keyword matching for detection.
/// </summary>
public partial class ContentFilter : IContentFilter
{
    // --- Violence / Self-Harm keywords and patterns ---
    private static readonly string[] ViolenceKeywords =
    [
        "kill yourself", "commit suicide", "end your life", "hurt yourself",
        "self-harm", "cut yourself", "hang yourself", "jump off",
        "how to make a bomb", "how to make explosives", "how to poison",
        "stab", "shoot them", "murder them", "attack them"
    ];

    // --- Sexually explicit keywords ---
    private static readonly string[] ExplicitKeywords =
    [
        "explicit sexual", "pornographic", "sexual intercourse",
        "genitalia", "masturbat", "orgasm", "erotic content",
        "sexually arousing", "nude photo", "sex act"
    ];

    // --- Hate speech keywords ---
    private static readonly string[] HateSpeechKeywords =
    [
        "kill all", "exterminate", "genocide", "ethnic cleansing",
        "racial superiority", "white power", "death to all",
        "subhuman", "inferior race"
    ];

    // --- PII detection patterns ---
    private static readonly Regex[] PiiPatterns =
    [
        EmailPattern(),
        PhonePattern(),
        SsnPattern(),
        CreditCardPattern(),
    ];

    /// <inheritdoc />
    public ContentFilterResult Filter(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return new ContentFilterResult { IsBlocked = false };
        }

        var violations = new List<ContentViolationCategory>();
        var lowerContent = content.ToLowerInvariant();

        // Check violence / self-harm
        if (ContainsAnyKeyword(lowerContent, ViolenceKeywords))
        {
            violations.Add(ContentViolationCategory.ViolenceOrSelfHarm);
        }

        // Check sexually explicit content
        if (ContainsAnyKeyword(lowerContent, ExplicitKeywords))
        {
            violations.Add(ContentViolationCategory.SexuallyExplicit);
        }

        // Check hate speech
        if (ContainsAnyKeyword(lowerContent, HateSpeechKeywords))
        {
            violations.Add(ContentViolationCategory.HateSpeech);
        }

        // Check PII
        if (ContainsPii(content))
        {
            violations.Add(ContentViolationCategory.PersonallyIdentifiableInformation);
        }

        return new ContentFilterResult
        {
            IsBlocked = violations.Count > 0,
            ViolationCategories = violations
        };
    }

    private static bool ContainsAnyKeyword(string content, string[] keywords)
    {
        foreach (var keyword in keywords)
        {
            if (content.Contains(keyword, StringComparison.Ordinal))
            {
                return true;
            }
        }
        return false;
    }

    private static bool ContainsPii(string content)
    {
        foreach (var pattern in PiiPatterns)
        {
            if (pattern.IsMatch(content))
            {
                return true;
            }
        }
        return false;
    }

    // Email pattern: basic email detection
    [GeneratedRegex(@"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}", RegexOptions.None, matchTimeoutMilliseconds: 1000)]
    private static partial Regex EmailPattern();

    // Phone pattern: various phone formats (US and international)
    [GeneratedRegex(@"(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}", RegexOptions.None, matchTimeoutMilliseconds: 1000)]
    private static partial Regex PhonePattern();

    // SSN pattern: XXX-XX-XXXX
    [GeneratedRegex(@"\b\d{3}-\d{2}-\d{4}\b", RegexOptions.None, matchTimeoutMilliseconds: 1000)]
    private static partial Regex SsnPattern();

    // Credit card pattern: 4 groups of 4 digits
    [GeneratedRegex(@"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b", RegexOptions.None, matchTimeoutMilliseconds: 1000)]
    private static partial Regex CreditCardPattern();
}
