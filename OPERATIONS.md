# Guía de Operaciones — Base de Datos-PARA RESET DE LA NUBE Y LOCAL

## Regla de oro
- `supabase/migrations/` → solo archivos generados con `supabase migration new`. Nunca mover SQL de prueba aquí.
- `supabase/scratch/` → carpeta segura para SQL de prueba locales. No afecta nada.
- Cualquier archivo fuera de `migrations/`, `functions/` y `seed.sql` no dispara el deploy.

---

## 1. Reset local (volver al estado limpio)

Usar cuando: algo se rompió localmente, querés empezar desde cero, o verificar que las migraciones funcionan.

```
cd C:\Users\bianc\Desktop\proyecto-panela\supabase\mi-proyecto
..\supabase db reset
```

Esto aplica en orden:
1. Todas las migraciones (schema completo)
2. `seed.sql` (cooperativas, certificados, configuraciones — **sin usuarios**, `db reset` no carga usuarios solo)

Si además querés usuarios de prueba (móvil y web) en local, correr manualmente en el SQL Editor de `http://localhost:54323` (o con `psql`) el contenido de `supabase/test_seed.sql` — ver sección "Creación de usuarios" más abajo.

También conviene revisar la sección "Catálogos y datos de referencia por cooperativa" más abajo — en particular, marcas y presentaciones probablemente queden vacías tras el reset.

---

## 2. Hacer un cambio de schema (migración)

Usar cuando: nueva tabla, nueva columna, cambio en función, cambio en RLS, datos de referencia nuevos.

### Paso a paso:

```
-- 1. Crear el archivo de migración
..\supabase migration new nombre_descriptivo_del_cambio

-- 2. Editar el archivo generado en supabase/migrations/
--    Escribir el SQL del cambio (CREATE TABLE, ALTER TABLE, etc.)

-- 3. Verificar que funciona localmente
..\supabase db reset

-- 4. Si todo está bien, subir a la nube
git add supabase/migrations/
git commit -m "feat: descripción del cambio"
git push origin main
```

GitHub Actions aplica la migración automáticamente a la nube.

---

## 3. Cambio en una Edge Function

```
-- 1. Editar el archivo en supabase/functions/nombre-funcion/index.ts
-- 2. Subir
git add supabase/functions/
git commit -m "feat: descripción del cambio"
git push origin main
```

GitHub Actions deployea las funciones automáticamente.

---

## 4. Setup inicial de un entorno nuevo en la nube

Hacer estos pasos UNA SOLA VEZ al crear un proyecto nuevo en Supabase:

```
[ ] 1. GitHub Actions corre automáticamente → schema aplicado
[ ] 2. SQL Editor (nube) → ejecutar contenido de supabase/seed.sql
[ ] 3. Usuarios iniciales → ver sección "Creación de usuarios" más abajo
        (para un entorno de pruebas: supabase/test_seed.sql;
         para producción con usuarios reales: crear cada uno vía las
         Edge Functions, no hay un seed de usuarios reales listo todavía)
[ ] 4. Authentication → Hooks → Custom Access Token → activar custom_access_token_hook
[ ] 5. Edge Functions → Manage secrets → agregar:
        SUPABASE_URL = URL del proyecto
        SUPABASE_SERVICE_ROLE_KEY = Settings → API → service_role key
```

---

## Creación de usuarios (móvil y web)

Hay dos caminos, según si es carga masiva de prueba o alta de un usuario real puntual.

### Carga masiva de prueba (local o nube de staging)

`supabase/test_seed.sql` reemplaza a los antiguos `web_admin_seed.sql` / `dev_seed.sql` / `real_users_seed.sql` (esos 3 archivos **ya no existen** — si los ves referenciados en algún lado viejo, es este archivo). No se aplica solo con `db reset`: hay que correrlo a mano en el SQL Editor (local `http://localhost:54323`, o el de la nube).

Crea, para Norandino y CAES:
- 2 admins **web**, directo en `auth.users` + `web_users`. Usuario y contraseña son iguales (ej. `admin_norandino` / `admin_norandino`).
- ~60 usuarios **móvil** (productores/técnicos) vía `public.users` + `setup_dni_user_auth(dni, dni, cooperativa)`. Login = DNI, contraseña = el mismo DNI.

⚠️ Contraseñas obvias a propósito — es solo para pruebas. **Nunca correr esto contra una nube con datos reales.**

También existe `supabase/test_dual_role_seed.sql` (escenario de prueba puntual: un técnico que también es productor), mismo criterio, solo pruebas.

### Datos reales (módulos + usuarios), reemplazo de test_seed.sql

Cuando ya no se quiere usar `test_seed.sql` (contraseñas obvias, datos ficticios) y se pasa a un entorno con datos reales, dos archivos separados, mismo mecanismo técnico que `test_seed.sql` pero con valores reales:

- **`supabase/modules_seed.sql`** — los `coop_modules` reales. Norandino: 42 módulos reales (reemplazan los 10 placeholder de `test_seed.sql`, tomados de `usuarios_norandino.csv`). CAES: todavía los 10 de `test_seed.sql`, sin confirmar como reales — pendiente de una lista real cuando se retome esa cooperativa.
- **`supabase/real_users_seed.sql`** — admins web + usuarios móvil reales, mismo patrón (`auth.users` + `web_users` para web; `public.users` + `setup_dni_user_auth` para móvil), con nombres/DNIs/credenciales reales. Hoy solo Norandino (123 personas + 1 admin web + 1 admin sistema + 2 técnicos inventados). Incluye 3 parcelas por productor.
- **`supabase/catalogs_seed.sql`** — marcas y presentaciones (`plant_brand_catalog`/`plant_presentation_catalog`), ver sección de catálogos más abajo.
- **`supabase/certified_workers_seed.sql`** — plantilla con nombres falsos, 1 por cada uno de los 42 módulos reales de Norandino (comentario indica a qué módulo corresponde cada fila) — reemplazar nombres cuando llegue la lista real.
- **`supabase/quotas_seed.sql`** — plantilla con cupo_kg/year falsos (5000 kg, 2026) para los 80 productores reales de Norandino, certificación Orgánica — reemplazar por los valores reales.

### CAES — todo de prueba (sin datos reales todavía)

Carpeta aparte `supabase/caes/`, mismo criterio que Norandino pero 100% con datos falsos (DNIs en el rango `91000000`-`91000099`, no pisan con los de Norandino). Orden para correr:

1. `caes/modules_caes.sql` — los 10 módulos de CAES (ya existían en `modules_seed.sql`, extraídos acá aparte).
2. `caes/users_caes.sql` — admin web (`admincaes`/`admincaes`), admin_sistema, 2 técnicos, 10 admin_modulo (1 por módulo) y 30 productores (3 por módulo, con 3 parcelas cada uno) — todos falsos.
3. `caes/catalogs_caes.sql` — marcas/presentaciones para CAES (mismo contenido que `catalogs_seed.sql`, filtrado explícito a CAES; si ya corriste el compartido, este no inserta nada nuevo).
4. `caes/certified_workers_caes.sql` — 1 trabajador falso por módulo.
5. `caes/quotas_caes.sql` — cupo falso (3000 kg, 2026, Orgánica) para los 30 productores de prueba.

Reemplazar todo por datos reales cuando lleguen (mismo patrón que se usó para pasar de `test_seed.sql` a los archivos reales de Norandino).

Igual que `test_seed.sql`: **carga manual en los dos entornos** (no se agregan a `config.toml`, no corren solos con `db reset`). Correr `modules_seed.sql` primero (los usuarios se asignan a esos módulos), después `real_users_seed.sql`. No correr junto con `test_seed.sql` — son alternativos, no complementarios.

### Alta de un usuario real, uno por uno

- **Móvil** → Edge Function `register-user`. La invoca un admin ya logueado desde la app móvil (requiere JWT de un `admin_sistema`/`admin_modulo` existente — no sirve para el primer usuario de un cooperativa nueva, hace falta al menos un admin ya creado por otra vía).
- **Web** → Edge Function `register-web-user`. ⚠️ A diferencia de `register-user`, esta función **no valida quién la llama** (no chequea token ni rol, solo los datos del body) — pensada para invocarla manualmente (curl/Postman) durante el setup, no para exponerla sin más control. Si se va a usar en producción con usuarios reales, conviene revisar/agregarle un chequeo de rol antes.

---

## Catálogos y datos de referencia por cooperativa (checklist)

Después de un reset (local o nube) o al dar de alta una cooperativa nueva, esto es lo que hay que revisar/cargar además de los usuarios. Están en el orden en que conviene hacerlos.

| Catálogo | Tabla | ¿Tiene pantalla en la web? | Dónde está documentado |
|---|---|---|---|
| Trabajadores certificados | `certified_workers` | No — solo SQL | `CERTIFIED_WORKERS.md` + `supabase/certified_workers_seed.sql` (plantilla, nombres falsos) |
| Cupos por productor | `producer_quotas` | No — solo SQL (todavía) | `QUOTA_SYSTEM.md` + `supabase/quotas_seed.sql` (plantilla, cupo falso) |
| Clientes | `plant_clients` | **Sí** — se crea desde `OrdenesPage.jsx` | No hace falta SQL |
| Marcas | `plant_brand_catalog` | No — solo SQL | `supabase/catalogs_seed.sql` |
| Presentaciones | `plant_presentation_catalog` | No — solo SQL, ni siquiera se lee en la web todavía | `supabase/catalogs_seed.sql` |

### ⚠️ Marcas y presentaciones — probablemente quedan vacías tras un reset

La migración `20260712144100_create_presentation_brand_catalogs.sql` intenta pre-cargar marcas/presentaciones por defecto para Norandino y CAES con un `INSERT ... SELECT ... FROM cooperatives CROSS JOIN (...)`. El problema: **las migraciones corren TODAS antes que `seed.sql`** (ver sección 1), y `cooperatives` recién se llena en `seed.sql`. O sea que en un `db reset` de verdad desde cero, esa migración se ejecuta contra una tabla `cooperatives` todavía vacía → el `INSERT` no inserta nada, aunque el comentario de la migración diga que sí.

**Después de cada reset, verificar** si estas tablas tienen filas:
```sql
SELECT cooperative_id, count(*) FROM plant_brand_catalog GROUP BY 1;
SELECT cooperative_id, count(*) FROM plant_presentation_catalog GROUP BY 1;
```
Si salen vacías, correr `supabase/catalogs_seed.sql` a mano (mismo contenido que traía la migración, separado en su propio archivo de carga manual). Esa es la lista por defecto (2026-07-12) — todavía no confirmada como real; reemplazar el contenido de ese archivo cuando llegue la lista real de marcas/presentaciones de cada cooperativa.

---

## 5. Reset de la nube (caso de emergencia)

Solo si es absolutamente necesario volver a un estado limpio en la nube.

```
 Reset de la nube paso a paso

  Paso 1 — Borrar el schema en el SQL Editor de Supabase (nube)

  DROP SCHEMA public CASCADE;
  CREATE SCHEMA public;
  GRANT ALL ON SCHEMA public TO postgres;
  GRANT ALL ON SCHEMA public TO public;

  Esto borra absolutamente todo — tablas, funciones, datos, RLS.

  ---
  Paso 2 — Reaplicar el schema

  Ir a GitHub → Actions → "Deploy to Supabase Pre-prod" → Run workflow

  Esto aplica TODAS las migraciones del repo en orden cronológico (baseline + todas
  las que hayas subido después). supabase db push detecta que la tabla de migraciones
  está vacía tras el reset y las re-aplica todas desde cero.

  ---
  Paso 3 — Seed de datos de referencia

  En el SQL Editor de la nube, pegar y ejecutar el contenido de supabase/seed.sql.

  ---
  Paso 4 — Usuarios

  Ver sección "Creación de usuarios" más arriba: supabase/test_seed.sql para un
  entorno de pruebas, o alta manual vía Edge Functions si son usuarios reales.
  También revisar "Catálogos y datos de referencia por cooperativa" (marcas y
  presentaciones probablemente queden vacías, ver esa sección).

  ---
  Paso 5 — Reactivar el Auth Hook

  Authentication → Hooks → Custom Access Token → activar custom_access_token_hook

  ---
  Paso 6 — Verificar los secrets de Edge Functions

  Edge Functions → Manage secrets → confirmar que SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY siguen ahí (normalmente
  sobreviven al reset del schema).

  ---
  La diferencia clave con el reset local:

  ┌────────────┬───────────────────┬──────────────────────────────────────┐
  │            │       Local       │                 Nube                 │
  ├────────────┼───────────────────┼──────────────────────────────────────┤
  │ Comando    │ supabase db reset │ Manual — SQL Editor + GitHub Actions │
  ├────────────┼───────────────────┼──────────────────────────────────────┤
  │ Riesgo     │ Ninguno           │ Alto si hay datos reales             │
  ├────────────┼───────────────────┼──────────────────────────────────────┤
  │ Frecuencia │ Cuando quieras    │ Solo emergencias                     │
  └────────────┴───────────────────┴──────────────────────────────────────┘
```



---

## Qué archivos van dónde

| Archivo | Propósito | Se despliega |
|---|---|---|
| `supabase/migrations/*.sql` | Cambios de schema | Automático con git push |
| `supabase/functions/*/index.ts` | Edge Functions | Automático con git push |
| `supabase/seed.sql` | Datos de referencia iniciales | Automático en `db reset` (local); manual una vez por entorno en la nube |
| `supabase/test_seed.sql` | Usuarios de prueba (móvil + web), ambas cooperativas | Manual, nunca automático — ni siquiera `db reset` lo corre solo |
| `supabase/test_dual_role_seed.sql` | Escenario de prueba puntual (usuario dual rol) | Manual, solo pruebas |
| `supabase/scratch/*.sql` | SQL de prueba/exploración | Nunca — solo local |
