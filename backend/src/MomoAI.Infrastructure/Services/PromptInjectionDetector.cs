using System.Text.RegularExpressions;
using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Detects prompt injection attempts using regex patterns and keyword matching.
/// Covers system instruction overrides, role impersonation, and delimiter escapes.
/// </summary>
public partial class PromptInjectionDetector : IPromptInjectionDetector
{
    // System instruction override patterns
    private static readonly Regex[] SystemOverridePatterns =
    [
        SystemOverridePattern1(),
        SystemOverridePattern2(),
        SystemOverridePattern3(),
        SystemOverridePattern4(),
        SystemOverridePattern5(),
    ];

    // Role impersonation patterns
    private static readonly Regex[] RoleImpersonationPatterns =
    [
        RoleImpersonationPattern1(),
        RoleImpersonationPattern2(),
        RoleImpersonationPattern3(),
        RoleImpersonationPattern4(),
    ];

    // Delimiter escape patterns
    private static readonly Regex[] DelimiterEscapePatterns =
    [
        DelimiterEscapePattern1(),
        DelimiterEscapePattern2(),
        DelimiterEscapePattern3(),
        DelimiterEscapePattern4(),
        DelimiterEscapePattern5(),
        DelimiterEscapePattern6(),
    ];

    /// <inheritdoc />
    public PromptInjectionResult Detect(string message)
    {
        if (string.IsNullOrWhiteSpace(message))
        {
            return new PromptInjectionResult { IsInjectionDetected = false };
        }

        var normalized = message.ToLowerInvariant();

        // Check system instruction override
        foreach (var pattern in SystemOverridePatterns)
        {
            if (pattern.IsMatch(normalized))
            {
                return new PromptInjectionResult
                {
                    IsInjectionDetected = true,
                    Category = PromptInjectionCategory.SystemInstructionOverride
                };
            }
        }

        // Check role impersonation
        foreach (var pattern in RoleImpersonationPatterns)
        {
            if (pattern.IsMatch(normalized))
            {
                return new PromptInjectionResult
                {
                    IsInjectionDetected = true,
                    Category = PromptInjectionCategory.RoleImpersonation
                };
            }
        }

        // Check delimiter escape (case-insensitive already via regex options)
        foreach (var pattern in DelimiterEscapePatterns)
        {
            if (pattern.IsMatch(message))
            {
                return new PromptInjectionResult
                {
                    IsInjectionDetected = true,
                    Category = PromptInjectionCategory.DelimiterEscape
                };
            }
        }

        return new PromptInjectionResult { IsInjectionDetected = false };
    }

    // --- System instruction override patterns ---

    [GeneratedRegex(@"ignore\s+(all\s+)?(previous|above|prior)\s+(instructions|prompts|rules)", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex SystemOverridePattern1();

    [GeneratedRegex(@"disregard\s+(all\s+)?(previous|above|prior)\s+(instructions|prompts|rules)", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex SystemOverridePattern2();

    [GeneratedRegex(@"forget\s+(all\s+)?(previous|above|prior)\s+(instructions|prompts|rules)", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex SystemOverridePattern3();

    [GeneratedRegex(@"new\s+instructions\s*:", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex SystemOverridePattern4();

    [GeneratedRegex(@"override\s+(system|previous)\s+(prompt|instructions)", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex SystemOverridePattern5();

    // --- Role impersonation patterns ---

    [GeneratedRegex(@"you\s+are\s+now\s+", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex RoleImpersonationPattern1();

    [GeneratedRegex(@"act\s+as\s+(a|an|if you were)\s+", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex RoleImpersonationPattern2();

    [GeneratedRegex(@"pretend\s+(you\s+are|to\s+be)\s+", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex RoleImpersonationPattern3();

    [GeneratedRegex(@"from\s+now\s+on\s+you\s+(are|will\s+be)\s+", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex RoleImpersonationPattern4();

    // --- Delimiter escape patterns ---

    [GeneratedRegex(@"```\s*system", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex DelimiterEscapePattern1();

    [GeneratedRegex(@"\[SYSTEM\]", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex DelimiterEscapePattern2();

    [GeneratedRegex(@"</system>", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex DelimiterEscapePattern3();

    [GeneratedRegex(@"<\|im_start\|>system", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex DelimiterEscapePattern4();

    [GeneratedRegex(@"###\s*(system|instruction|prompt)", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex DelimiterEscapePattern5();

    [GeneratedRegex(@"<system>", RegexOptions.IgnoreCase, matchTimeoutMilliseconds: 1000)]
    private static partial Regex DelimiterEscapePattern6();
}
