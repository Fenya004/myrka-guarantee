import React from 'react';

export default function Button({ children, onClick, variant = 'primary', disabled = false, className = '' }) {
  const base = "w-full py-3 rounded-xl font-bold transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed";
  const variants = {
    primary: "bg-gradient-to-r from-purple-600 to-pink-600 hover:shadow-lg hover:shadow-purple-500/50",
    secondary: "bg-gray-700 hover:bg-gray-600",
    danger: "bg-red-600 hover:bg-red-500"
  };
  return (
    <button onClick={onClick} disabled={disabled} className={`${base} ${variants[variant]} ${className}`}>
      {children}
    </button>
  );
}