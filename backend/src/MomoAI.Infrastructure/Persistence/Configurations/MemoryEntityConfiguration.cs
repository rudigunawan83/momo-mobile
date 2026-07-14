using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MomoAI.Infrastructure.Persistence.Entities;

namespace MomoAI.Infrastructure.Persistence.Configurations;

/// <summary>
/// EF Core configuration for MemoryEntity with pgvector column and RLS index.
/// </summary>
public class MemoryEntityConfiguration : IEntityTypeConfiguration<MemoryEntity>
{
    public void Configure(EntityTypeBuilder<MemoryEntity> builder)
    {
        builder.ToTable("memories");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Id)
            .HasColumnName("id");

        builder.Property(m => m.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        builder.Property(m => m.Summary)
            .HasColumnName("summary")
            .HasMaxLength(500)
            .IsRequired();

        builder.Property(m => m.Content)
            .HasColumnName("content")
            .HasMaxLength(2000)
            .IsRequired();

        builder.Property(m => m.Type)
            .HasColumnName("type")
            .HasConversion<string>()
            .IsRequired();

        builder.Property(m => m.ImportanceScore)
            .HasColumnName("importance_score")
            .IsRequired();

        builder.Property(m => m.Embedding)
            .HasColumnName("embedding")
            .HasColumnType("vector(1536)")
            .IsRequired();

        builder.Property(m => m.IsFavorite)
            .HasColumnName("is_favorite")
            .HasDefaultValue(false);

        builder.Property(m => m.OccurredAt)
            .HasColumnName("occurred_at")
            .IsRequired();

        builder.Property(m => m.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        builder.Property(m => m.Tags)
            .HasColumnName("tags")
            .HasColumnType("jsonb");

        // Index for user-scoped queries (enforces memory isolation at query level)
        builder.HasIndex(m => m.UserId)
            .HasDatabaseName("ix_memories_user_id");

        // Index for vector similarity search scoped to user
        builder.HasIndex(m => new { m.UserId, m.Id })
            .HasDatabaseName("ix_memories_user_id_id");
    }
}
