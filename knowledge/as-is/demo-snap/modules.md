# demo-snap - modulos y tecnologia (as-is)
> [GENERADO v8] desde demo-snap@`404a3ee005f8` el 2026-07-18 17:06 UTC - NO EDITAR A MANO.

**Stack detectado:** express
**Rol declarado (repos.yaml):** snapshot exportado

## Estructura
```
migrations
src
```

## Servicios externos detectados
- PostgreSQL
- Redis
- HTTP-saliente

_(inferidos de dependencias y esquemas de conexion en config;_
_indican con que habla el repo ademas de sus rutas HTTP)_

## Dependencias directas
- `axios 1.6.0 [runtime]`
- `express 4.19.0 [runtime]`
- `pg 8.11.0 [runtime]`
- `redis 4.6.0 [runtime]`
- `eslint 8.50.0 [dev]`
- `jest 29.0.0 [dev]`

## Datos
- `migrations/` (1 archivos de migracion/esquema)

## Infraestructura y CI
- `Dockerfile`

## Comandos del repo
- `npm run lint  ->  eslint src`
- `npm run start  ->  node src/index.js`
- `npm run test  ->  jest`
