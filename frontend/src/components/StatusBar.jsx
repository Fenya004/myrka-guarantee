import React from 'react';

export default function StatusBar() {
  return (
    <div className="bg-black/50 backdrop-blur-sm p-3 flex justify-between items-center border-b border-purple-500/30">
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-full bg-gradient-to-r from-purple-500 to-pink-500 flex items-center justify-center font-bold">M</div>
        <span className="font-semibold">Гарант Сервис | Myrka_1337</span>
      </div>
      <div className="text-xs bg-gray-800 px-3 py-1 rounded-full">Баланс: 0 ₽</div>
    </div>
  );
}