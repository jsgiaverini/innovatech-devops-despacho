import Navbar from "./Layouts/Navbar";
import Footer from "./Layouts/Footer";
import { DashboardCards } from "./CrudAdmin/DashboardCards";

export const CrudAdmin = () => (
  <div className="grid grid-cols-[auto_1fr] min-h-screen bg-gray-50">
    <div className="col-span-1">
      <Navbar />
    </div>
    <main className="overflow-y-auto p-6">
      <DashboardCards />
      <Footer />
    </main>
  </div>
);
