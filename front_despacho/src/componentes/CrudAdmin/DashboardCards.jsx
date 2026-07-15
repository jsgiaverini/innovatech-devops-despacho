import { useState } from "react";
import { CardComponent } from "./CardComponent";
import { TableCompras } from "./TableCompras";
import { TableDespachos } from "./TableDespachos";

export const DashboardCards = () => {
  const [vistaActiva, setVistaActiva] = useState(null);

  return (
    <section>
      <div className="flex justify-center">
        <CardComponent
          title="Consultar órdenes de compra 💰"
          description="Revisa las últimas órdenes de compra para generar su despacho."
          buttonText="Consultar"
          onClick={() => setVistaActiva("compras")}
        />
        <CardComponent
          title="Revisar órdenes de despacho 🚚"
          description="Consulta los despachos, modifica los intentos o cierra la orden."
          buttonText="Consultar"
          onClick={() => setVistaActiva("despachos")}
        />
      </div>

      {vistaActiva === "compras" && <TableCompras />}
      {vistaActiva === "despachos" && <TableDespachos />}
    </section>
  );
};
