import { useCallback, useEffect, useState } from "react";
import axios from "axios";
import { Modal } from "./Modal";
import { FormCierreDespacho } from "./FormCierreDespacho";

export const TableDespachos = () => {
  const [despachos, setDespachos] = useState([]);
  const [error, setError] = useState("");
  const [openModal, setOpenModal] = useState(false);
  const [despachoSeleccionado, setDespachoSeleccionado] = useState(null);

  const cargarDespachos = useCallback(async () => {
    try {
      setError("");
      const response = await axios.get("/api/v1/despachos");
      setDespachos(response.data);
    } catch (requestError) {
      console.error("No fue posible cargar los despachos:", requestError);
      setError("No fue posible cargar las órdenes de despacho.");
    }
  }, []);

  useEffect(() => {
    cargarDespachos();
  }, [cargarDespachos]);

  const abrirModal = (despacho) => {
    setDespachoSeleccionado(despacho);
    setOpenModal(true);
  };

  const cerrarYRecargar = async () => {
    setOpenModal(false);
    setDespachoSeleccionado(null);
    await cargarDespachos();
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
                  <th className="pr-10">Orden de despacho</th>
                  <th className="pr-10">Orden de compra</th>
                  <th className="pr-10">Dirección de entrega</th>
                  <th className="pr-10">Fecha de despacho</th>
                  <th className="pr-10">Patente del camión</th>
                  <th className="pr-10">Estado</th>
                  <th className="pr-10">Intentos</th>
                  <th className="pr-10"><span className="sr-only">Acciones</span></th>
                </tr>
              </thead>
              <tbody>
                {despachos.map((despacho) => (
                  <tr key={despacho.idDespacho}>
                    <td className="pr-10 py-10">{despacho.idDespacho}</td>
                    <td className="pr-10 py-10">{despacho.idCompra}</td>
                    <td className="pr-10 py-10">{despacho.direccionCompra}</td>
                    <td className="pr-10 py-10">{despacho.fechaDespacho}</td>
                    <td className="pr-10 py-10">{despacho.patenteCamion}</td>
                    <td className="pr-10 py-10">
                      {despacho.despachado ? "Despacho entregado" : "Despacho pendiente"}
                    </td>
                    <td className="pr-10 py-10">{despacho.intento}</td>
                    <td>
                      <button
                        type="button"
                        onClick={() => abrirModal(despacho)}
                        className="py-1 bg-orange-200 px-8 rounded-xl shadow-md hover:bg-orange-300/70 transition-all duration-300"
                      >
                        Editar despacho
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
        {despachoSeleccionado && (
          <FormCierreDespacho
            despacho={despachoSeleccionado}
            onClose={cerrarYRecargar}
          />
        )}
      </Modal>
    </>
  );
};
