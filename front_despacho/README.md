# Frontend - Sistema de Despachos Innovatech

Aplicación React + Vite para la gestión de órdenes de compra y despachos.

## Desarrollo

```bash
npm install
npm run dev
```

## Docker

```bash
docker build -t front-despacho .
docker run -p 80:8080 -e VENTAS_HOST=localhost -e DESPACHOS_HOST=localhost front-despacho
```

Para documentación completa del proyecto, ver [README.md](../README.md) en la raíz.
