namespace MomoAI.Application.DTOs;

/// <summary>
/// Request DTO for the AI Gateway to generate a response.
/// </summary>
public record AIRequest
{
    public string SystemPrompt { get; init; } = string.Empty;
    public string UserMessage { get; init; } = string.Empty;
    public List<string> Context { get; init; } = new();
    public List<ChatMessageDto> RecentHistory { get; init; } = new();
    public double Temperature { get; init; } = 0.7;
    public int MaxTokens { get; init; } = 1024;
}
