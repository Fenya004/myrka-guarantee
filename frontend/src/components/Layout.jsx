import React from 'react';
import { Outlet } from 'react-router-dom';
import StatusBar from './StatusBar';

export default function Layout() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-black text-white">
      <StatusBar />
      <main className="container mx-auto px-4 py-6 max-w-md pb-24">
        <Outlet />
      </main>
    </div>
  );
}