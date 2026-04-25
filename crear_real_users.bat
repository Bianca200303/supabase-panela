@echo off
REM =====================================================================
REM Inserta modulos, 10 admin_modulo y 20 productores (Norandino)
REM
REM ORDEN: supabase db reset  →  este bat
REM NO ejecutar despues de crear_dev_users.bat
REM =====================================================================

cd /d "%~dp0"

set MODO=local
REM Para nube: cambia MODO=nube y pon tu connection string
set DB_URL=postgresql://postgres:Fiorella2303@db.csrsgkkzxcuwsamloedb.supabase.co:5432/postgres

if "%MODO%"=="local" (
  docker cp "supabase\real_users_seed.sql" supabase_db_mi-proyecto:/tmp/real_users_seed.sql
  docker exec supabase_db_mi-proyecto psql -U postgres postgres -f /tmp/real_users_seed.sql
) else (
  docker cp "supabase\real_users_seed.sql" supabase_db_mi-proyecto:/tmp/real_users_seed.sql
  docker exec supabase_db_mi-proyecto psql "%DB_URL%" -f /tmp/real_users_seed.sql
)

echo.
echo ──────────────────────────────────────────────────────────────────
echo  Admin modulo Norandino (contrasena = DNI):
echo    Huancabamba → 11300001   Ayabaca     → 11300002
echo    Morropon    → 11300003   Pacaipampa  → 11300004
echo    Sondor      → 11300005   Montero     → 11300006
echo    Sapillica   → 11300007   Lalaquiz    → 11300008
echo    El Faique   → 11300009   Canchaque   → 11300010
echo.
echo  Productores: 11400001–11400020 (2 por modulo)
echo ──────────────────────────────────────────────────────────────────
pause
