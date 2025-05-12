using Microsoft.EntityFrameworkCore;
using XWifiApi.Models;

namespace XWifiApi.Data
{
    public class XWifiDbContext : DbContext
    {
        public XWifiDbContext(DbContextOptions<XWifiDbContext> options) : base(options)
        {
        }

        public DbSet<WiFiNetwork> WiFiNetworks { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<WiFiNetwork>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Ssid).IsRequired();
                entity.Property(e => e.Password).IsRequired(false);
                entity.Property(e => e.Capabilities).IsRequired();
                entity.Property(e => e.Notes);
                entity.Property(e => e.CreatedAt)
                    .HasColumnType("timestamp with time zone")
                    .HasDefaultValueSql("CURRENT_TIMESTAMP");
            });
        }

        public override int SaveChanges()
        {
            ProcessDateTimeProperties();
            return base.SaveChanges();
        }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            ProcessDateTimeProperties();
            return base.SaveChangesAsync(cancellationToken);
        }

        private void ProcessDateTimeProperties()
        {
            foreach (var entry in ChangeTracker.Entries())
            {
                foreach (var property in entry.Properties)
                {
                    if (property.Metadata.ClrType == typeof(DateTime) || 
                        property.Metadata.ClrType == typeof(DateTime?))
                    {
                        if (property.CurrentValue is DateTime dateTime && 
                            dateTime.Kind != DateTimeKind.Utc)
                        {
                            property.CurrentValue = dateTime.Kind == DateTimeKind.Local
                                ? dateTime.ToUniversalTime()
                                : DateTime.SpecifyKind(dateTime, DateTimeKind.Utc);
                        }
                    }
                }
            }
        }
    }
} 