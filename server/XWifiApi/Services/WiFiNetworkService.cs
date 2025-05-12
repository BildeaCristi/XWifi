using Microsoft.EntityFrameworkCore;
using XWifiApi.Data;
using XWifiApi.Models;

namespace XWifiApi.Services
{
    public class WiFiNetworkService
    {
        private readonly XWifiDbContext _dbContext;
        private readonly ILogger<WiFiNetworkService> _logger;

        public WiFiNetworkService(XWifiDbContext dbContext, ILogger<WiFiNetworkService> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<IEnumerable<WiFiNetwork>> GetAllAsync()
        {
            return await _dbContext.WiFiNetworks
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();
        }

        public async Task<WiFiNetwork?> GetByIdAsync(string id)
        {
            return await _dbContext.WiFiNetworks.FindAsync(id);
        }

        public async Task<WiFiNetwork> AddAsync(WiFiNetwork network)
        {
            if (string.IsNullOrEmpty(network.Id))
            {
                network.Id = DateTime.UtcNow.Ticks.ToString();
            }

            if (string.IsNullOrEmpty(network.Ssid))
            {
                throw new ArgumentException("SSID is required");
            }

            if (string.IsNullOrEmpty(network.Capabilities))
            {
                network.Capabilities = "Unknown";
            }

            if (network.CreatedAt == default)
            {
                network.CreatedAt = DateTime.UtcNow;
            }
            else if (network.CreatedAt.Kind != DateTimeKind.Utc)
            {
                network.CreatedAt = network.CreatedAt.Kind == DateTimeKind.Local
                    ? network.CreatedAt.ToUniversalTime()
                    : DateTime.SpecifyKind(network.CreatedAt, DateTimeKind.Utc);
            }

            await _dbContext.WiFiNetworks.AddAsync(network);
            await _dbContext.SaveChangesAsync();
            
            _logger.LogInformation("Added network {Ssid} with ID {Id}", network.Ssid, network.Id);
            return network;
        }

        public async Task<bool> DeleteAsync(string id)
        {
            var network = await _dbContext.WiFiNetworks.FindAsync(id);
            if (network == null)
            {
                return false;
            }

            _dbContext.WiFiNetworks.Remove(network);
            await _dbContext.SaveChangesAsync();
            
            _logger.LogInformation("Deleted network with ID {Id}", id);
            return true;
        }
    }
} 