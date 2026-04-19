# Crear usuarios admin (bootstrap móvil + web)

Lista para correr **después de cada `supabase db reset`**. Crea 4 usuarios admin: 1 móvil + 1 web por cada cooperativa.

## Credenciales

| Tipo | Cooperativa | DNI / Username | Password |
|------|-------------|----------------|----------|
| Móvil `admin_sistema` | Norandino | `11111111` | `11111111` |
| Móvil `admin_sistema` | CAES      | `22222222` | `22222222` |
| Web `admin_web`       | Norandino | `33333333` | `33333333` |
| Web `admin_web`       | CAES      | `44444444` | `44444444` |

## IDs de cooperativas

| Cooperativa | ID |
|-------------|-----|
| Norandino | `550e8400-e29b-41d4-a716-446655440001` |
| CAES      | `550e8400-e29b-41d4-a716-446655440002` |

---

## Paso 1 — Usuarios móvil (SQL)

Las edge functions exigen un caller admin autenticado, pero en bootstrap no existe ninguno → se crea por SQL. `admin_sistema` no requiere módulos asignados, así que es seguro.

Abre psql:

```bash
psql postgresql://postgres:postgres@localhost:54322/postgres
```

Y ejecuta:

```sql
-- ===== Admin móvil NORANDINO =====
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role)
VALUES ('11111111', 'Admin', 'Norandino',
        '550e8400-e29b-41d4-a716-446655440001', 'admin_sistema');

SELECT public.setup_dni_user_auth(
  '11111111',
  '11111111',
  '550e8400-e29b-41d4-a716-446655440001'::uuid
);

-- ===== Admin móvil CAES =====
INSERT INTO public.users (user_id, first_name, last_name, cooperative_id, role)
VALUES ('22222222', 'Admin', 'CAES',
        '550e8400-e29b-41d4-a716-446655440002', 'admin_sistema');

SELECT public.setup_dni_user_auth(
  '22222222',
  '22222222',
  '550e8400-e29b-41d4-a716-446655440002'::uuid
);
```

---

## Paso 2 — Usuarios web (curl a edge function)

Para web sí usamos la edge function `register-web-user` porque valida unicidad de username por cooperativa y construye el email virtual correcto (`username.COOPCODE@web.local`). La función no exige caller autenticado.

Antes de correr, obtén la `Publishable` key:

```bash
..\supabase status
```

Reemplaza `<ANON_KEY>` con la `Publishable` key (ej: `sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH`).

```bash
# ===== Admin web NORANDINO =====
curl -X POST http://127.0.0.1:54321/functions/v1/register-web-user \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "33333333",
    "password": "33333333",
    "firstName": "Admin",
    "lastName": "Norandino",
    "role": "admin_web",
    "cooperativeId": "550e8400-e29b-41d4-a716-446655440001"
  }'

# ===== Admin web CAES =====
curl -X POST http://127.0.0.1:54321/functions/v1/register-web-user \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "44444444",
    "password": "44444444",
    "firstName": "Admin",
    "lastName": "CAES",
    "role": "admin_web",
    "cooperativeId": "550e8400-e29b-41d4-a716-446655440002"
  }'
```

Cada call debe responder `{"success": true}`.

---

## Paso 3 — Verificar

```sql
SELECT user_id, first_name, role, cooperative_id FROM public.users;
SELECT username, first_name, role, cooperative_id FROM public.web_users;
```

Deberías ver 2 filas en cada tabla.

---

## Paso 4 — Login

### App móvil (Flutter)

Login con DNI + password. Ejemplo Norandino:
```
DNI:      11111111
Password: 11111111
```

Comando para correr:
```bash
flutter run --flavor caes --dart-define=COOPERATIVE_CODE=CAES --dart-define=USE_LOCAL_SUPABASE=true
flutter run --flavor norandino --dart-define=COOPERATIVE_CODE=NORANDINO --dart-define=USE_LOCAL_SUPABASE=true
```

Para celular físico, edita `flutter/lib/core/app_config.dart` con tu IP local:
```dart
return 'http://192.168.1.XX:54321'; // ipconfig
```

### Web (React)

Login con username + password. Cada deploy apunta a una sola cooperativa vía `VITE_COOPERATIVE_ID`:
```
Norandino → username 33333333 / pass 33333333
CAES      → username 44444444 / pass 44444444
```

---

## Notas

- El **resto de usuarios** (admin_modulo, tecnico_campo, productor, operador) se crean **desde la app** con un admin logueado. Por SQL te perderías la asignación obligatoria de módulos.
- Cada `supabase db reset` borra todos los usuarios → repetir Paso 1 + Paso 2.
- Si una edge function falla tras cambios: `docker restart supabase_edge_runtime_mi-proyecto`.
