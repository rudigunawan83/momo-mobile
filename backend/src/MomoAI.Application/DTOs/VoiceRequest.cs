namespace MomoAI.Application.DTOs;

/// <summary>
/// Request DTO for processing a voice message.
/// Transcription is performed on the mobile device; this DTO carries
/// the transcribed text to be routed through the same AI pipeline as text messages.
/// </summary>
public record VoiceRequest
{
    public Guid UserId { get; init; }

    /// <summary>
    /// Transcribed text from the Speech-to-Text engine on the mobile device.
    /// This is the primary input processed through the AI pipeline.
    /// </summary>
    public string TranscribedText { get; init; } = string.Empty;

    /// <summary>
    /// Raw audio data (optional, for potential server-side processing or storage).
    /// </summary>
    public byte[] AudioData { get; init; } = Array.Empty<byte>();

    /// <summary>
    /// Audio format of the raw audio data (e.g., "wav", "m4a").
    /// </summary>
    public string AudioFormat { get; init; } = "wav";

    /// <summary>
    /// Duration of the recording in seconds. Must be between 0.5 and 60.
    /// </summary>
    public double DurationSeconds { get; init; }
}
