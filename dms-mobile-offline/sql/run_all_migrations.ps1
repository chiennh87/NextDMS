# Run all DMS migrations in order
 = 'Biadmin@123'
 = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
 = 'dms'
 = 'postgres'
System.Management.Automation.Internal.Host.InternalHost = 'localhost'
 = 'c:\Projects\NextDMS\NextDMS\dms-mobile-offline\sql'

 = @(
    '00_schema_base.sql',
    '01_schema_value_set.sql',
    '02_schema_outlets.sql',
    '03_seed_data.sql'
)

foreach ( in ) {
     = Join-Path  
    Write-Host "=== Running  ===" -ForegroundColor Cyan
    &  -h System.Management.Automation.Internal.Host.InternalHost -U  -d  -f  2>&1
    if ( -ne 0) {
        Write-Host "FAILED: " -ForegroundColor Red
        exit 1
    }
}
Write-Host "All migrations completed successfully!" -ForegroundColor Green
