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
1. Migración baseline (schema completo)
2. seed.sql (cooperativas, certificados, configuraciones)

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
[ ] 3. SQL Editor (nube) → ejecutar contenido de supabase/web_admin_seed.sql
        (cambiar contraseñas antes de ejecutar)
[ ] 4. Authentication → Hooks → Custom Access Token → activar custom_access_token_hook
[ ] 5. Edge Functions → Manage secrets → agregar:
        SUPABASE_URL = URL del proyecto
        SUPABASE_SERVICE_ROLE_KEY = Settings → API → service_role key
```

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
  Paso 4 — Crear los admins web

  En el SQL Editor de la nube, pegar y ejecutar supabase/web_admin_seed.sql.

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
| `supabase/seed.sql` | Datos de referencia iniciales | Manual (una vez por entorno) |
| `supabase/web_admin_seed.sql` | Admins web iniciales | Manual (una vez por entorno) |
| `supabase/dev_seed.sql` | Usuarios de prueba locales | Solo local (db reset) |
| `supabase/real_users_seed.sql` | Usuarios reales Norandino | Manual cuando se necesite |
| `supabase/scratch/*.sql` | SQL de prueba/exploración | Nunca — solo local |
