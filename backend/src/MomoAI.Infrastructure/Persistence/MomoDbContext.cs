using Microsoft.EntityFrameworkCore;
using MomoAI.Infrastructure.Persistence.Entities;

namespace MomoAI.Infrastructure.Persistence;

/// <summary>
/// EF Core DbContext for Momo AI with pgvector extension support.
/// </summary>
public class MomoDbContext : DbContext
{
    public MomoDbContext(DbContextOptions<MomoDbContext> options) : base(options)
    {
    }

    public DbSet<MemoryEntity> Memories => Set<MemoryEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Enable pgvector extension
        modelBuilder.HasPostgresExtension("vector");

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MomoDbContext).Assembly);
    }
}
