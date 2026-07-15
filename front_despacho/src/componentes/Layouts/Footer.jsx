import logo from "../../assets/images/logo2.png";

function Footer() {
  return (
    <footer className="bg-teal-500 p-6 text-center w-full rounded-xl">
      <div className="flex flex-col items-center gap-3">
        <img src={logo} alt="Logo de Innovatech" className="w-16 h-16" />
        <span className="text-sm text-gray-900">
          © 2026 Innovatech. Sistema de gestión de despachos.
        </span>
      </div>
    </footer>
  );
}

export default Footer;
