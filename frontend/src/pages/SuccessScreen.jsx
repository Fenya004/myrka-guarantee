import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import NeonCard from '../components/NeonCard';
import Button from '../components/Button';

export default function SuccessScreen() {
  const { dealId } = useParams();
  const [deal, setDeal] = useState(null);
  useEffect(() => { fetch(`/api/deal/${dealId}`).then(res => res.json()).then(setDeal); }, []);
  if (!deal) return <div>Загрузка...</div>;
  return (
    <div className="space-y-5 pb-20">
      <NeonCard>
        <h2 className="text-2xl font-bold text-green-400 text-center">✅ Сделка завершена!</h2>
        <p className="text-center mt-2">Код купона передан покупателю.</p>
        <div className="bg-gray-900 p-3 text-center font-mono text-lg rounded-lg mt-2 break-all">{deal.couponCode}</div>
        <Button variant="secondary" className="mt-3" onClick={() => navigator.clipboard.writeText(deal.couponCode)}>Скопировать код</Button>
      </NeonCard>
      <Button variant="danger" onClick={() => alert('Открыть спор (будет позже)')}>Открыть спор</Button>
      <Button variant="secondary" onClick={() => window.location.href = '/'}>На главную</Button>
    </div>
  );
}