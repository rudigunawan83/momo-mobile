using System.Collections.Concurrent;
using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Persistence;

/// <summary>
/// In-memory implementation of IChatMessageRepository for development without a database.
/// </summary>
public class InMemoryChatMessageRepository : IChatMessageRepository
{
    private readonly ConcurrentDictionary<Guid, List<ChatMessageDto>> _messages = new();

    /// Tracks the "current user" for SaveMessageAsync since ChatMessageDto has no UserId.
    private Guid _lastQueriedUserId = Guid.Empty;

    public Task<List<ChatMessageDto>> GetRecentMessagesAsync(Guid userId, int limit, CancellationToken ct)
    {
        _lastQueriedUserId = userId;

        if (_messages.TryGetValue(userId, out var messages))
        {
            List<ChatMessageDto> recent;
            lock (messages)
            {
                recent = messages
                    .OrderByDescending(m => m.CreatedAt)
                    .Take(limit)
                    .ToList();
            }
            return Task.FromResult(recent);
        }

        return Task.FromResult(new List<ChatMessageDto>());
    }

    public Task SaveMessageAsync(ChatMessageDto message, CancellationToken ct)
    {
        // Associate with the last queried user (ChatService always queries before saving)
        var userId = _lastQueriedUserId != Guid.Empty ? _lastQueriedUserId : Guid.Empty;
        var userMessages = _messages.GetOrAdd(userId, _ => new List<ChatMessageDto>());
        lock (userMessages)
        {
            userMessages.Add(message);
        }
        return Task.CompletedTask;
    }

    public Task<ConversationHistory> GetHistoryAsync(Guid userId, int page, int pageSize, CancellationToken ct)
    {
        List<ChatMessageDto> allMessages;
        if (_messages.TryGetValue(userId, out var messages))
        {
            lock (messages)
            {
                allMessages = messages.OrderByDescending(m => m.CreatedAt).ToList();
            }
        }
        else
        {
            allMessages = new List<ChatMessageDto>();
        }

        var pagedMessages = allMessages
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult(new ConversationHistory
        {
            Messages = pagedMessages,
            Page = page,
            PageSize = pageSize,
            TotalCount = allMessages.Count
        });
    }
}
