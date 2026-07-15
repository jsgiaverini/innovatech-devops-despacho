import { useForm } from "react-hook-form";
import Swal from "sweetalert2";
import axios from "axios";

export const FormCierreDespacho = ({ despacho, onClose }) => {
  const { register, handleSubmit } = useForm({
    defaultValues: {
      intento: despacho.intento,
      despachado: String(despacho.despachado),
    },
  });

  const onSubmit = async (data) => {
    const despachoActualizado = {
      fechaDespacho: despacho.fechaDespacho,
      patenteCamion: despacho.patenteCamion,
      intento: Number(data.intento),
      idCompra: despacho.idCompra,
      direccionCompra: despacho.direccionCompra,
      valorCompra: despacho.valorCompra,
      despachado: data.despachado === "true",
    };

    try {
      await axios.put(
        `/api/v1/despachos/${despacho.idDespacho}`,
        despachoActualizado,
      );
      await Swal.fire({
        title: "Despacho modificado 🚚",
        text: "El despacho fue actualizado correctamente.",
        icon: "success",
        confirmButtonText: "Aceptar",
      });
      onClose();
    } catch (requestError) {
      console.error("Error al modificar el despacho:", requestError);
      await Swal.fire({
        title: "No fue posible modificar el despacho",
        text: "Revisa la conexión con el servicio e inténtalo nuevamente.",
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
        Editar y cerrar despacho
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">ID del despacho</label>
        <input readOnly type="text" value={despacho.idDespacho} className="border border-gray-300 rounded-lg block w-full p-1 text-slate-400" />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Fecha de despacho</label>
        <input readOnly type="date" value={despacho.fechaDespacho} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Patente del camión</label>
        <input readOnly type="text" value={despacho.patenteCamion} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Intentos de entrega</label>
        <input type="number" min="0" className="border border-gray-300 rounded-lg block w-full p-1" {...register("intento", { required: true, min: 0 })} />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Estado del despacho</label>
        <select className="border border-gray-300 rounded-lg block w-full p-1" {...register("despachado", { required: true })}>
          <option value="false">Despacho abierto</option>
          <option value="true">Cerrar despacho</option>
        </select>
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">ID de compra</label>
        <input readOnly type="text" value={despacho.idCompra} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Dirección de compra</label>
        <input readOnly type="text" value={despacho.direccionCompra} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Valor de compra</label>
        <input readOnly type="text" value={despacho.valorCompra} className="border border-gray-300 rounded-lg block w-full text-slate-400 p-1" />
      </div>
      <button className="py-6 px-14 rounded-lg bg-teal-600 text-white font-bold mb-14" type="submit">
        Modificar despacho
      </button>
    </form>
  );
};
