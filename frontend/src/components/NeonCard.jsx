import React from 'react';

export default function NeonCard({ children, className = '' }) {
  return (
    <div className={`bg-gray-800/40 backdrop-blur-sm rounded-2xl border border-purple-500/30 shadow-lg shadow-purple-500/10 p-5 ${className}`}>
      {children}
    </div>
  );
}