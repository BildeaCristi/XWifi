using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace XWifiApi.Data.Migrations
{
    /// <inheritdoc />
    public partial class UpdatedWiFiNetworkModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WiFiNetworks",
                columns: table => new
                {
                    Id = table.Column<string>(type: "text", nullable: false),
                    Ssid = table.Column<string>(type: "text", nullable: false),
                    Bssid = table.Column<string>(type: "text", nullable: true),
                    Password = table.Column<string>(type: "text", nullable: false),
                    Capabilities = table.Column<string>(type: "text", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    Frequency = table.Column<int>(type: "integer", nullable: false),
                    Level = table.Column<int>(type: "integer", nullable: false),
                    IsConnected = table.Column<bool>(type: "boolean", nullable: false),
                    IpAddress = table.Column<string>(type: "text", nullable: true),
                    Ipv6Address = table.Column<string>(type: "text", nullable: true),
                    Subnet = table.Column<string>(type: "text", nullable: true),
                    Gateway = table.Column<string>(type: "text", nullable: true),
                    Broadcast = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WiFiNetworks", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WiFiNetworks");
        }
    }
}
