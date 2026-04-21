import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import NeonCard from '../components/NeonCard';
import Button from '../components/Button';

export default function DealScreen() {
  const navigate = useNavigate();
  const [amount, setAmount] = useState('');
  const [coupon, setCoupon] = useState('');
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(false);
  const tg = window.Telegram?.WebApp;
  const userId = tg?.initDataUnsafe?.user?.id?.toString() || 'test_user';

  const fetchMyDeals = async () => {
    const res = await fetch(`/api/user/deals?userId=${userId}`);
    if (res.ok) setDeals(await res.json());
  };
  useEffect(() => { fetchMyDeals(); }, []);

  const createDeal = async () => {
    if (!amount || !coupon) return alert('Заполните поля');
    setLoading(true);
    const res = await fetch('/api/deal/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount: parseInt(amount), couponCode: coupon, buyerTelegramId: userId })
    });
    const data = await res.json();
    if (res.ok) navigate(`/deal/${data.dealId}`);
    else alert('Ошибка');
    setLoading(false);
  };

  return (
    <div className="space-y-6 pb-20">
      <NeonCard>
        <h2 className="text-xl font-bold mb-3">Новая сделка</h2>
        <input type="number" placeholder="Сумма (₽)" value={amount} onChange={e => setAmount(e.target.value)} className="w-full p-3 rounded-xl bg-gray-800 border border-gray-700 mb-3" />
        <input type="text" placeholder="Код купона" value={coupon} onChange={e => setCoupon(e.target.value)} className="w-full p-3 rounded-xl bg-gray-800 border border-gray-700 mb-4" />
        <Button onClick={createDeal} disabled={loading}>Создать сделку</Button>
      </NeonCard>

      {deals.length > 0 && (
        <NeonCard>
          <div className="flex justify-between items-center mb-3">
            <h3 className="font-bold">Мои сделки</h3>
            <button className="text-xs text-purple-400">Все →</button>
          </div>
          {deals.slice(0, 3).map(deal => (
            <div key={deal.id} className="flex justify-between py-2 border-b border-gray-700 cursor-pointer hover:bg-gray-700/30 px-2 rounded" onClick={() => navigate(`/deal/${deal.id}`)}>
              <span>Сделка #{deal.id.slice(-5)}</span>
              <span className="font-mono">{deal.amount} ₽</span>
            </div>
          ))}
        </NeonCard>
      )}

      <NeonCard>
        <h3 className="font-bold mb-2">Последние действия</h3>
        <div className="space-y-2 text-sm">
          <div className="text-gray-300">• Сделка #12459 – Покупатель нажал «Я оплатил»</div>
          <div className="text-gray-300">• Сделка #12458 – Покупатель нажал «Я оплатил»</div>
          <div className="text-gray-300">• Сделка #12457 – Подтверждена</div>
        </div>
      </NeonCard>

      <NeonCard>
        <h3 className="font-bold mb-3">Правила сервиса</h3>
        <ul className="text-sm space-y-2 text-gray-300">
          <li>✓ Безопасность сделок – мы гарант между покупателем и продавцом</li>
          <li>✓ Честные условия – правила прозрачны и едины для всех</li>
          <li>✓ Поддержка 24/7 – наша команда всегда готова помочь</li>
          <li>✓ Арбитраж – решаем споры справедливо и оперативно</li>
        </ul>
        <div className="mt-4 flex items-center gap-2">
          <input type="checkbox" id="agree" className="w-4 h-4" />
          <label htmlFor="agree" className="text-sm">Я ознакомился и согласен</label>
        </div>
        <Button variant="secondary" className="mt-3">Продолжить</Button>
      </NeonCard>
    </div>
  );
}