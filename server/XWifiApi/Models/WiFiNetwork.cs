using System.Text.Json.Serialization;

namespace XWifiApi.Models
{
    public class WiFiNetwork
    {
        public string Id { get; set; } = string.Empty;
        public string Ssid { get; set; } = string.Empty;

        // Make password optional
        public string? Password { get; set; }

        public string Capabilities { get; set; } = string.Empty;
        public string Notes { get; set; } = string.Empty;

        private DateTime _createdAt = DateTime.UtcNow;

        public DateTime CreatedAt
        {
            get => _createdAt;
            set => _createdAt = value.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(value, DateTimeKind.Utc)
                : value.ToUniversalTime();
        }
    }
}