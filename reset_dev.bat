@echo off
REM =================================================================
REM reset_dev.bat — Reset completo + seed de desarrollo
REM Doble clic desde: supabase/mi-proyecto/
REM =================================================================

cd /d "%~dp0"
set PGPASSWORD=postgres
set PSQL=psql -h 127.0.0.1 -p 54322 -U postgres -d postgres

echo.
echo [1/3] Reseteando base de datos (seed.sql)...
..\supabase.exe db reset
if %ERRORLEVEL% NEQ 0 ( echo ERROR en db reset. & pause & exit /b 1 )

echo.
echo [2/3] Aplicando datos de referencia...
%PSQL% -f "supabase\data_seed.sql"
if %ERRORLEVEL% NEQ 0 ( echo ERROR en data_seed.sql. & pause & exit /b 1 )

echo.
echo [3/3] Creando modulos, usuarios y productores de desarrollo...
%PSQL% -f "supabase\dev_seed.sql"
if %ERRORLEVEL% NEQ 0 ( echo ERROR en dev_seed.sql. & pause & exit /b 1 )

echo.
echo ================================================================
echo  Listo.
echo ================================================================
echo.
echo  MOVIL  (DNI / password iguales)
echo  -------------------------------------------------------
echo  admin_sistema  Norandino : 11111111
echo  admin_sistema  CAES      : 22222222
echo  admin_modulo   Nor  Mod1 : 11100001   Mod2 : 11100002
echo  admin_modulo   CAES Mod1 : 22100001   Mod2 : 22100002
echo  productor      Nor  Mod1 : 11200001   Mod2 : 11200002
echo  productor      CAES Mod1 : 22200001   Mod2 : 22200002
echo.
echo  WEB  (usuario / password iguales)
echo  -------------------------------------------------------
echo  Norandino : 33333333
echo  CAES      : 44444444
echo ================================================================
echo.
pause
