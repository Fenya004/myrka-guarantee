import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import NeonCard from '../components/NeonCard';
import Button from '../components/Button';
import Timer from '../components/Timer';
import DealSteps from '../components/DealSteps';

export default function PaymentScreen() {
  const { dealId } = useParams();
  const navigate = useNavigate();
  const [deal, setDeal] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchDeal = async () => {
    const res = await fetch(`/api/deal/${dealId}`);
    const data = await res.json();
    setDeal(data);
    if (data.status === 'PAID' || data.status === 'COMPLETED') navigate(`/success/${dealId}`);
  };
  useEffect(() => { fetchDeal(); }, [dealId]);

  const initiatePayment = async () => {
    setLoading(true);
    const res = await fetch(`/api/deal/${dealId}/initiate-payment`, { method: 'POST' });
    if (res.ok) fetchDeal();
    else { const err = await res.json(); alert(err.error); }
    setLoading(false);
  };
  const markPaid = async () => {
    setLoading(true);
    const res = await fetch(`/api/deal/${dealId}/mark-paid`, { method: 'POST' });
    if (res.ok) alert('Ожидайте подтверждения администратора');
    else { const err = await res.json(); alert(err.error); }
    fetchDeal();
    setLoading(false);
  };
  const copyText = (text) => { navigator.clipboard.writeText(text); alert('Скопировано'); };

  if (!deal) return <div className="text-center p-8">Загрузка...</div>;
  const total = deal.amount + deal.commission;

  return (
    <div className="space-y-5 pb-20">
      <NeonCard>
        <h1 className="text-2xl font-bold text-center">Сделка #{deal.id.slice(-5)}</h1>
        <DealSteps currentStatus={deal.status} />
        <div className="text-center mt-2">
          <span className="text-3xl font-bold">{deal.amount} ₽</span>
          <span className="text-sm text-gray-400 ml-2">+ комиссия {deal.commission} ₽</span>
        </div>
      </NeonCard>

      {deal.status === 'CREATED' && <Button onClick={initiatePayment} disabled={loading}>Оплатить</Button>}

      {deal.status === 'PENDING_PAYMENT' && (
        <>
          <NeonCard>
            <h3 className="font-bold mb-2">Реквизиты для оплаты</h3>
            <div className="bg-gray-900 p-3 rounded-lg break-all">{deal.paymentDetails || 'Реквизиты не загружены'}</div>
            {deal.paymentDetails && <Button variant="secondary" className="mt-3" onClick={() => copyText(deal.paymentDetails)}>Скопировать реквизиты</Button>}
            <div className="mt-4 text-center text-sm text-gray-400">Время на оплату:</div>
            <Timer deadline={deal.paymentDeadline} onExpire={fetchDeal} />
            <div className="text-xs text-center text-gray-500 mt-2">После истечения времени реквизиты станут недействительными</div>
          </NeonCard>
          <Button onClick={markPaid} disabled={loading}>Я оплатил</Button>
        </>
      )}

      {deal.status === 'WAITING_CONFIRMATION' && (
        <NeonCard><div className="text-yellow-400 text-center">⏳ Ожидаем подтверждения администратора...</div></NeonCard>
      )}
      {deal.status === 'DISPUTE' && (
        <NeonCard><div className="text-red-400 text-center">⚠️ Открыт спор. Администратор свяжется с вами.</div></NeonCard>
      )}
    </div>
  );
}