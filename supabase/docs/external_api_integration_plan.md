# Plan: Integración de Software Externo vía API propia

## Fecha: 2026-07-20

## Contexto

Un software externo (de otro proceso, no nuestro) necesita consumir información
de nuestro sistema. Todavía no está definido exactamente qué datos va a
consultar — este documento deja registrado el enfoque de seguridad ya
decidido, para no tener que rediscutirlo cuando se defina el alcance exacto.

---

## Opciones evaluadas

| Opción | Descripción | Por qué sí/no |
|---|---|---|
| Compartir credenciales directas (`service_role` o conexión a la base) | El externo se conecta directo a nuestra base/API interna | **Descartada.** Si se filtra la credencial, expone todo el sistema, no solo lo que necesitaban. |
| Rol Postgres dedicado + vistas + API key vía PostgREST | Rol de solo lectura con RLS propia sobre vistas curadas | Válida, pero acceso sigue siendo directo a la base — más difícil de auditar y de revocar de forma aislada. |
| **Edge Function propia como gateway (elegida)** | Función nuestra que autentica con API key propia y devuelve solo el JSON curado | Aísla completamente el acceso, control total de qué se expone, revocable sin tocar el resto del sistema. |
| Exportación programada / webhook | Envío periódico o por evento, sin acceso de consulta en vivo | Más segura aún, pero no sirve si el externo necesita consultar en tiempo real. A reconsiderar si el caso de uso no requiere tiempo real. |

---

## Solución elegida: Edge Function como gateway

El sistema externo **nunca** se conecta directo a nuestra base de datos ni
recibe nuestras credenciales internas (`service_role`, `anon key`). Solo le
habla a una función propia (`external-data-api`) que actúa de filtro:

```
Sistema externo  --(HTTP + API key propia)-->  external-data-api (Edge Function)
                                                        |
                                                  service_role interno
                                                  (nunca sale de la función)
                                                        |
                                                 Nuestra base de datos
```

**Por qué es seguro:**
- La API key del externo es propia de esta integración, distinta de cualquier
  clave interna nuestra. Se revoca sin afectar nada más del sistema.
- El `service_role` se usa solo dentro de la función — nunca se expone al
  llamador.
- La función devuelve exclusivamente el JSON que nosotros decidamos armar en
  el `SELECT` interno, nunca tablas completas ni el esquema real.

**Implementación ya lista** (placeholder, pendiente de definir el alcance
real de datos):

`supabase/mi-proyecto/supabase/functions/external-data-api/index.ts`

Sigue la misma convención que las demás funciones del proyecto (`serve` +
`createClient`, CORS, helper `error()`).

---

## Pasos para activarla (pendientes, no ejecutados todavía)

1. Generar la API key del externo (ej. `openssl rand -hex 32`) — **no
   guardarla en el repo**.
2. `supabase secrets set EXTERNAL_API_KEY=<valor-generado>`
3. `supabase functions deploy external-data-api`
4. El sistema externo llama a
   `https://<proyecto>.supabase.co/functions/v1/external-data-api`
   con el header `x-api-key: <valor-generado>`.

---

## Pendiente antes de activar en serio

- [ ] Definir junto al equipo del sistema externo **exactamente qué datos**
      necesitan consultar (qué tablas/campos, con qué frecuencia).
- [ ] Reemplazar el `SELECT` placeholder (`plant_orders` completadas) por la
      consulta real acordada.
- [ ] Decidir si el acceso debe ser de solo lectura permanente o si conviene
      evaluar la opción de exportación programada/webhook en vez de consulta
      en vivo, según qué tan en tiempo real necesiten el dato.
- [ ] Generar y guardar la API key de forma segura (gestor de secretos del
      equipo, no en texto plano compartido).
