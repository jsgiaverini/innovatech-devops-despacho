export const Modal = ({ open, onClose, children }) => {
  if (!open) return null;

  return (
    <div
      role="presentation"
      onClick={onClose}
      className="fixed inset-0 z-10 flex justify-center items-center bg-black/50"
    >
      <div
        role="dialog"
        aria-modal="true"
        onClick={(event) => event.stopPropagation()}
        className="flex flex-col items-end bg-white rounded-lg"
      >
        <button
          type="button"
          aria-label="Cerrar ventana"
          onClick={onClose}
          className="z-20 -mb-6 fill-emerald-500 hover:fill-emerald-600 font-bold hover:text-4xl text-3xl bg-teal-600 text-white transition-all w-14 h-14"
        >
          ×
        </button>
        {children}
      </div>
    </div>
  );
};
