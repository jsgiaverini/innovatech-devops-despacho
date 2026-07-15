# Frontend de Despachos Innovatech

Aplicación React + Vite para consultar compras, generar despachos y actualizar su estado.

## Desarrollo local

Con los backends ejecutándose en los puertos 8080 y 8081:

```bash
npm ci
npm run lint
npm run dev
```

Vite redirige `/api/v1/ventas` a `localhost:8080` y `/api/v1/despachos` a `localhost:8081`.

## Docker

La forma recomendada es iniciar todo el proyecto desde la raíz:

```bash
docker compose up -d --build
```

El frontend queda disponible en `http://localhost`.
