import React from 'react';

export default function DealSteps({ currentStatus }) {
  const steps = ['CREATED', 'PENDING_PAYMENT', 'WAITING_CONFIRMATION', 'PAID', 'COMPLETED'];
  const titles = ['Создана', 'Оплата', 'Подтверждение', 'Завершена'];
  let activeIndex = steps.indexOf(currentStatus);
  if (activeIndex >= titles.length) activeIndex = titles.length - 1;
  if (activeIndex < 0) activeIndex = 0;
  return (
    <div className="flex justify-between mb-6">
      {titles.map((title, idx) => (
        <div key={idx} className="text-center flex-1">
          <div className={`text-xs mb-1 ${idx <= activeIndex ? 'text-purple-400' : 'text-gray-500'}`}>{title}</div>
          <div className={`h-1 rounded-full ${idx <= activeIndex ? 'bg-purple-500' : 'bg-gray-700'}`}></div>
        </div>
      ))}
    </div>
  );
}