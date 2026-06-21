# Base de Datos — Sistema de Trazabilidad de Panela

Backend del sistema de trazabilidad para producción de panela artesanal, implementado sobre **Supabase** (PostgreSQL 17). Diseñado para las cooperativas peruanas **NORANDINO** y **CAES**.

## Tecnologías

- **Supabase** — Backend-as-a-Service (Auth, PostgreSQL, Edge Functions, RLS)
- **PostgreSQL 17** — Base de datos relacional
- **TypeScript / Deno** — Edge Functions (funciones serverless)

## Estructura

```
supabase/
├── migrations/       # Schema completo de la BD (55 tablas)
├── functions/        # Edge Functions (autenticación y registro de usuarios)
├── seed.sql          # Datos iniciales obligatorios
├── config.toml       # Configuración del entorno local
└── docs/             # Documentación de tablas y flujos
.github/
└── workflows/
    └── deploy.yml    # CI/CD: despliega migraciones y funciones automáticamente
```

## Requisitos previos

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Configuración local

```bash
# 1. Iniciar Supabase local
supabase start

# 2. Aplicar schema completo + datos semilla
supabase db reset
```

Al finalizar, el panel de administración queda disponible en `http://localhost:54323`.

## Configuración en producción (Supabase Cloud)

```bash
# 1. Vincular con el proyecto remoto
supabase link --project-ref <ID_DEL_PROYECTO>

# 2. Aplicar migraciones
supabase db push

# 3. Ejecutar seed.sql manualmente desde el SQL Editor de Supabase Studio
```

## Edge Functions

| Función | Descripción |
|---|---|
| `auth-dni` | Autenticación de usuarios móviles por DNI y contraseña |
| `auth-web` | Autenticación de usuarios web por username y contraseña |
| `register-user` | Registro de nuevos usuarios móviles |
| `register-web-user` | Registro de nuevos usuarios web |
| `update-user-role` | Actualización de rol de usuario |
| `register-homogenization` | Registro de proceso de homogenización en planta |

## CI/CD

El archivo `.github/workflows/deploy.yml` despliega automáticamente las migraciones y Edge Functions al hacer push a `main`. Requiere configurar los siguientes secretos en el repositorio de GitHub:

- `SUPABASE_ACCESS_TOKEN` — Token de acceso personal de Supabase
- `SUPABASE_DB_PASSWORD` — Contraseña de la base de datos del proyecto

## Base de datos

La BD cuenta con **55 tablas** organizadas en 8 dominios: cooperativas y usuarios, producción de campo, certificaciones, controles de calidad, salidas e inventario, planta y envasado, formatos documentarios y configuración dinámica.

Toda la seguridad de datos entre cooperativas se maneja mediante **Row-Level Security (RLS)** directamente en PostgreSQL.
