import { useForm } from "react-hook-form";
import Swal from "sweetalert2";
import axios from "axios";

export const FormDespacho = ({ venta, onClose }) => {
  const { register, handleSubmit } = useForm();

  const onSubmit = async (data) => {
    const nuevoDespacho = {
      fechaDespacho: data.fechaDespacho,
      patenteCamion: data.patenteCamion.trim(),
      intento: 0,
      despachado: false,
      idCompra: venta.idVenta,
      direccionCompra: venta.direccionCompra,
      valorCompra: venta.valorCompra,
    };

    let despachoCreado = null;

    try {
      const response = await axios.post("/api/v1/despachos", nuevoDespacho);
      despachoCreado = response.data;

      await axios.put(`/api/v1/ventas/${venta.idVenta}`, {
        despachoGenerado: true,
      });

      await Swal.fire({
        title: "Despacho registrado 🚚",
        text: "El despacho fue generado correctamente.",
        icon: "success",
        confirmButtonText: "Aceptar",
      });
      onClose();
    } catch (requestError) {
      if (despachoCreado?.idDespacho) {
        try {
          await axios.delete(`/api/v1/despachos/${despachoCreado.idDespacho}`);
        } catch (rollbackError) {
          console.error("No fue posible revertir el despacho incompleto:", rollbackError);
        }
      }

      console.error("Error al generar el despacho:", requestError);
      await Swal.fire({
        title: "No fue posible registrar el despacho",
        text: "Revisa la conexión con los servicios e inténtalo nuevamente.",
        icon: "error",
        confirmButtonText: "Aceptar",
      });
    }
  };

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className="flex flex-col justify-center text-center px-24 text-xl"
    >
      <div className="mx-auto text-3xl font-bold mb-10 text-teal-600">
        Ingreso de orden de despacho
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Fecha de despacho</label>
        <input
          type="date"
          className="border border-gray-300 rounded-lg block w-full p-1"
          {...register("fechaDespacho", { required: true })}
        />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Patente del camión</label>
        <input
          type="text"
          className="border border-gray-300 rounded-lg block w-full p-1"
          {...register("patenteCamion", { required: true })}
        />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Orden de compra asociada</label>
        <input readOnly type="number" value={venta.idVenta} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Dirección de entrega</label>
        <input readOnly type="text" value={venta.direccionCompra} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Valor de compra</label>
        <input readOnly type="number" value={venta.valorCompra} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <button className="py-6 px-14 rounded-lg bg-teal-600 text-white font-bold mb-14" type="submit">
        Asignar despacho
      </button>
    </form>
  );
};
