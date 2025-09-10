param (
    [string]$AppName = "BookingsApp",
    [string]$SitePath = "C:\inetpub\BookingsApp",
    [string]$SitePort = "8080",
    [string]$DatabaseName = "NTLong",
    [string]$SqlInstance = "localhost"
)

Write-Host "=== Deploying $AppName ==="

# 1. Tạo thư mục web
if (-not (Test-Path $SitePath)) {
    New-Item -Path $SitePath -ItemType Directory | Out-Null
    Write-Host "Created folder: $SitePath"
}

# 2. IIS: Tạo Application Pool
Import-Module WebAdministration
if (-not (Test-Path "IIS:\AppPools\$AppName")) {
    New-WebAppPool -Name $AppName
    Set-ItemProperty "IIS:\AppPools\$AppName" -Name "managedRuntimeVersion" -Value ""
    Write-Host "AppPool $AppName created"
}

# 3. IIS: Tạo Site
if (-not (Test-Path "IIS:\Sites\$AppName")) {
    New-Website -Name $AppName -Port $SitePort -PhysicalPath $SitePath -ApplicationPool $AppName
    Write-Host "Website $AppName bound to :$SitePort"
}

# 4. SQL Server: Tạo Login + User
$sql = @"
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'IIS APPPOOL\$AppName')
    CREATE LOGIN [IIS APPPOOL\$AppName] FROM WINDOWS;
GO

USE [$DatabaseName];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'IIS APPPOOL\$AppName')
    CREATE USER [IIS APPPOOL\$AppName] FOR LOGIN [IIS APPPOOL\$AppName];
GO

ALTER ROLE db_datareader ADD MEMBER [IIS APPPOOL\$AppName];
ALTER ROLE db_datawriter ADD MEMBER [IIS APPPOOL\$AppName];
-- ALTER ROLE db_owner ADD MEMBER [IIS APPPOOL\$AppName]; -- nếu muốn full quyền
"@

Invoke-Sqlcmd -ServerInstance $SqlInstance -Database "master" -Query $sql -Verbose

Write-Host "=== Deploy Done! ==="
