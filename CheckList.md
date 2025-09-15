# ✅ Checklist Deploy ASP.NET Core + IIS + SQL Server

## 1. Build & Publish
- Trong project `.csproj` chính (BookingsApp):
  <Target Name="AfterPublish" AfterTargets="Publish">
    <Exec Command="xcopy /y /s /e $(PublishDir)*.* C:\inetpub\BookingsApp\" />
  </Target>

- Publish:
  dotnet publish -c Release

- Code đọc file `.xml` phải dùng AppContext.BaseDirectory thay vì ..\..\.. để chạy được trong publish.

---

## 2. IIS Setup
1. Bật IIS features:  
   - Web Server (IIS)  
   - IIS Management Console  
   - .NET Core Hosting Bundle (cài từ Microsoft site).

2. Tạo Application Pool:
   - Tên: BookingsApp
   - .NET CLR: No Managed Code
   - Identity: mặc định là ApplicationPoolIdentity.

3. Tạo Site / Virtual Directory:
   - Physical Path: C:\inetpub\BookingsApp
   - Binding: http://*:8080 hoặc http://LAN-IP.

---

## 3. SQL Server Setup
🔑 Đây là chỗ hay bị quên nhất.

### Tạo login cho AppPool Identity
```sql
CREATE LOGIN [IIS APPPOOL\BookingsApp] FROM WINDOWS;
```

### Map login vào database
```sql
USE [NTLong];
CREATE USER [IIS APPPOOL\BookingsApp] FOR LOGIN [IIS APPPOOL\BookingsApp];
```

### Gán quyền
```sql
ALTER ROLE db_datareader ADD MEMBER [IIS APPPOOL\BookingsApp];
ALTER ROLE db_datawriter ADD MEMBER [IIS APPPOOL\BookingsApp];
-- Hoặc toàn quyền (test/dev)
ALTER ROLE db_owner ADD MEMBER [IIS APPPOOL\BookingsApp];
```

---

## 4. Connection String
Trong appsettings.json:
```json
"ConnectionStrings": {
  "DefaultConnection": "Server=localhost;Database=NTLong;Trusted_Connection=True;TrustServerCertificate=True"
}
```

---

## 5. Logging (Serilog example)

```csharp
Log.Logger = new LoggerConfiguration()
    .WriteTo.File("C:\inetpub\BookingsApp\logs\log-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();
```

---

## 6. Test
1. Mở http://localhost:8080 trên server → site chạy.  
2. Test từ máy khác trong LAN: http://<LAN-IP>:8080.  
3. Nếu báo lỗi login SQL → kiểm tra lại Login + User mapping.  

