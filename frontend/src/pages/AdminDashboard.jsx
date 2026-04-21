import React, { useState, useEffect } from 'react';
import NeonCard from '../components/NeonCard';
import Button from '../components/Button';

export default function AdminDashboard() {
  const [paymentDetails, setPaymentDetails] = useState('');
  const [adminSecret, setAdminSecret] = useState('');
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(false);

  // Загрузка списка сделок
  const fetchDeals = async () => {
    try {
      const res = await fetch('/api/admin/deals');
      if (res.ok) {
        const data = await res.json();
        setDeals(data);
      }
    } catch (err) {
      console.error('Ошибка загрузки сделок', err);
    }
  };

  useEffect(() => {
    fetchDeals();
  }, []);

  // Обновление реквизитов
  const updatePaymentDetails = async () => {
    if (!adminSecret) {
      alert('Введите admin secret');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/admin/set-payment-details', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ details: paymentDetails, adminSecret })
      });
      if (res.ok) {
        alert('Реквизиты успешно обновлены');
        setPaymentDetails('');
      } else {
        alert('Ошибка: неверный secret или проблема на сервере');
      }
    } catch (err) {
      alert('Ошибка соединения');
    }
    setLoading(false);
  };

  // Подтверждение сделки
  const confirmDeal = async (dealId) => {
    if (!adminSecret) {
      alert('Введите admin secret');
      return;
    }
    try {
      const res = await fetch('/api/admin/confirm-transaction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ dealId, adminSecret })
      });
      if (res.ok) {
        alert('Сделка подтверждена');
        fetchDeals();
      } else {
        alert('Ошибка подтверждения');
      }
    } catch (err) {
      alert('Ошибка соединения');
    }
  };

  // Отклонение сделки
  const rejectDeal = async (dealId) => {
    if (!adminSecret) {
      alert('Введите admin secret');
      return;
    }
    try {
      const res = await fetch('/api/admin/reject-transaction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ dealId, adminSecret })
      });
      if (res.ok) {
        alert('Сделка отклонена');
        fetchDeals();
      } else {
        alert('Ошибка отклонения');
      }
    } catch (err) {
      alert('Ошибка соединения');
    }
  };

  const waitingDeals = deals.filter(d => d.status === 'WAITING_CONFIRMATION');
  const otherDeals = deals.filter(d => d.status !== 'WAITING_CONFIRMATION').slice(0, 10);

  return (
    <div className="space-y-6 pb-20">
      <NeonCard>
        <h2 className="text-2xl font-bold mb-4">🔐 Админ-панель</h2>
        <input
          type="password"
          placeholder="Admin Secret"
          value={adminSecret}
          onChange={e => setAdminSecret(e.target.value)}
          className="w-full p-2 rounded bg-gray-800 border border-gray-700 mb-3"
        />
        <textarea
          placeholder="Введите реквизиты для оплаты (карта/кошелёк)"
          value={paymentDetails}
          onChange={e => setPaymentDetails(e.target.value)}
          className="w-full p-2 rounded bg-gray-800 border border-gray-700 mb-3"
          rows="3"
        />
        <Button onClick={updatePaymentDetails} disabled={loading}>
          Обновить реквизиты
        </Button>
      </NeonCard>

      <NeonCard>
        <h3 className="text-xl font-bold mb-3">⏳ Ожидают подтверждения</h3>
        {waitingDeals.length === 0 && <p className="text-gray-400">Нет сделок на подтверждении</p>}
        {waitingDeals.map(deal => (
          <div key={deal.id} className="border-b border-gray-700 py-3">
            <p><span className="font-mono">#{deal.id.slice(-6)}</span> — {deal.amount} ₽</p>
            <div className="flex gap-2 mt-2">
              <Button variant="primary" onClick={() => confirmDeal(deal.id)}>✅ Подтвердить</Button>
              <Button variant="danger" onClick={() => rejectDeal(deal.id)}>❌ Отклонить</Button>
            </div>
          </div>
        ))}
      </NeonCard>

      <NeonCard>
        <h3 className="text-xl font-bold mb-3">📋 Последние сделки</h3>
        {otherDeals.map(deal => (
          <div key={deal.id} className="flex justify-between py-2 border-b border-gray-700">
            <span className="font-mono">#{deal.id.slice(-6)}</span>
            <span>{deal.amount} ₽</span>
            <span className="text-xs text-gray-400">{deal.status}</span>
          </div>
        ))}
      </NeonCard>
    </div>
  );
}