@echo off
REM Crea modulos, admin_modulo y productores de prueba.
REM Ejecutar DESPUES de: supabase db reset + CREAR_USUARIO.md

cd /d "%~dp0"
docker cp "supabase\dev_seed.sql" supabase_db_mi-proyecto:/tmp/dev_seed.sql
docker exec supabase_db_mi-proyecto psql -U postgres postgres -f /tmp/dev_seed.sql

echo.
echo Listo. Modulos, admin_modulo y productores creados.
pause
