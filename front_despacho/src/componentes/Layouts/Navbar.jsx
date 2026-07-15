function Navbar() {
  return (
    <aside className="rounded-xl w-[250px] min-h-[880px] bg-teal-600 text-white sticky top-0 p-6 m-4">
      <h1 className="text-2xl font-bold mb-4">Innovatech</h1>
      <p className="font-semibold">Gestión de compras y despachos</p>
      <p className="mt-6 text-sm text-teal-50">
        Consulta órdenes pendientes, genera despachos y registra su estado de entrega.
      </p>
    </aside>
  );
}

export default Navbar;
