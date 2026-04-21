import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import DealScreen from './pages/DealScreen';
import PaymentScreen from './pages/PaymentScreen';
import SuccessScreen from './pages/SuccessScreen';
import AdminDashboard from './pages/AdminDashboard';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<DealScreen />} />
          <Route path="deal/:dealId" element={<PaymentScreen />} />
          <Route path="success/:dealId" element={<SuccessScreen />} />
          <Route path="admin" element={<AdminDashboard />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}