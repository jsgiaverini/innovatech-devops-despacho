import { useCallback, useEffect, useState } from "react";
import axios from "axios";
import { Modal } from "./Modal";
import { FormDespacho } from "./FormDespacho";

export const TableCompras = () => {
  const [ventas, setVentas] = useState([]);
  const [error, setError] = useState("");
  const [openModal, setOpenModal] = useState(false);
  const [ventaSeleccionada, setVentaSeleccionada] = useState(null);

  const cargarCompras = useCallback(async () => {
    try {
      setError("");
      const response = await axios.get("/api/v1/ventas");
      setVentas(response.data);
    } catch (requestError) {
      console.error("No fue posible cargar las órdenes de compra:", requestError);
      setError("No fue posible cargar las órdenes de compra.");
    }
  }, []);

  useEffect(() => {
    cargarCompras();
  }, [cargarCompras]);

  const abrirModal = (venta) => {
    setVentaSeleccionada(venta);
    setOpenModal(true);
  };

  const cerrarYRecargar = async () => {
    setOpenModal(false);
    setVentaSeleccionada(null);
    await cargarCompras();
  };

  return (
    <>
      {error && <p className="mb-4 text-center text-red-700">{error}</p>}
      <section className="grid text-center grid-cols-12 mb-8">
        <div className="col-span-12 flex justify-center">
          <div className="col-span-10 p-2 bg-white border border-gray-200 rounded-lg shadow h-full overflow-x-auto">
            <table className="table-fixed">
              <thead>
                <tr className="py-10">
                  <th className="pr-10">Orden de compra</th>
                  <th className="pr-10">Dirección</th>
                  <th className="pr-10">Fecha de compra</th>
                  <th className="pr-10">Valor total</th>
                  <th className="pr-10"><span className="sr-only">Acciones</span></th>
                </tr>
              </thead>
              <tbody>
                {ventas
                  .filter((venta) => !venta.despachoGenerado)
                  .map((venta) => (
                    <tr key={venta.idVenta}>
                      <td className="pr-10 py-10">{venta.idVenta}</td>
                      <td className="pr-10 py-10">{venta.direccionCompra}</td>
                      <td className="pr-10 py-10">{venta.fechaCompra}</td>
                      <td className="pr-10 py-10">${venta.valorCompra}</td>
                      <td>
                        <button
                          type="button"
                          onClick={() => abrirModal(venta)}
                          className="py-1 bg-orange-200 px-8 rounded-xl shadow-md hover:bg-orange-300/70 transition-all duration-300"
                        >
                          Generar despacho
                        </button>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>
      <Modal onClose={() => setOpenModal(false)} open={openModal}>
        {ventaSeleccionada && (
          <FormDespacho venta={ventaSeleccionada} onClose={cerrarYRecargar} />
        )}
      </Modal>
    </>
  );
};
