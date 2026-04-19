@echo off
REM =====================================================================
REM Crea los 2 admin_web (Norandino + CAES) llamando a la edge function
REM register-web-user. Ejecutar con doble clic despues de "supabase db reset".
REM =====================================================================

set ANON=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
set URL=http://127.0.0.1:54321/functions/v1/register-web-user

echo.
echo === Creando admin web NORANDINO ===
curl -s -X POST %URL% ^
  -H "apikey: %ANON%" ^
  -H "Authorization: Bearer %ANON%" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"33333333\",\"password\":\"33333333\",\"firstName\":\"Admin\",\"lastName\":\"Norandino\",\"role\":\"admin_web\",\"cooperativeId\":\"550e8400-e29b-41d4-a716-446655440001\"}"
echo.

echo.
echo === Creando admin web CAES ===
curl -s -X POST %URL% ^
  -H "apikey: %ANON%" ^
  -H "Authorization: Bearer %ANON%" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"44444444\",\"password\":\"44444444\",\"firstName\":\"Admin\",\"lastName\":\"CAES\",\"role\":\"admin_web\",\"cooperativeId\":\"550e8400-e29b-41d4-a716-446655440002\"}"
echo.

echo.
echo --------------------------------------------------------
echo Si ves {"success":true} dos veces, todo OK.
echo Login web:
echo   Norandino - usuario 33333333 - pass 33333333
echo   CAES      - usuario 44444444 - pass 44444444
echo --------------------------------------------------------
pause
