@echo off
title Myrka Guarantee - Setup and Run
echo ============================================================
echo   Гарант Сервис | Myrka - полная установка и запуск
echo ============================================================
echo.

set PROJECT_DIR=%CD%
if not "%PROJECT_DIR%"=="%USERPROFILE%\Desktop\myrka" (
    echo Рекомендуется запускать с рабочего стола в папке myrka
    echo Создаём папку myrka на рабочем столе...
    cd /d "%USERPROFILE%\Desktop"
    if not exist "myrka" mkdir myrka
    cd myrka
    set PROJECT_DIR=%CD%
    echo Перешли в %PROJECT_DIR%
)

echo [1/9] Проверка Node.js...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Node.js не найден. Установите с https://nodejs.org
    pause
    exit /b 1
)
node -v
echo.

echo [2/9] Создание структуры папок...
if exist backend rmdir /s /q backend
if exist frontend rmdir /s /q frontend
mkdir backend\prisma 2>nul
mkdir frontend\src\components 2>nul
mkdir frontend\src\pages 2>nul
mkdir frontend\public 2>nul
mkdir logs 2>nul

echo [3/9] Генерация файлов бэкенда...

:: backend package.json
(
echo {
echo   "name": "myrka-backend",
echo   "version": "1.0.0",
echo   "scripts": {
echo     "start": "node server.js"
echo   },
echo   "dependencies": {
echo     "@prisma/client": "^5.0.0",
echo     "cors": "^2.8.5",
echo     "dotenv": "^16.0.3",
echo     "express": "^4.18.2",
echo     "node-telegram-bot-api": "^0.61.0",
echo     "prisma": "^5.0.0",
echo     "sqlite3": "^5.1.6"
echo   }
echo }
) > backend\package.json

:: .env
(
echo DATABASE_URL="file:./dev.db"
echo TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN_HERE
echo ADMIN_CHAT_ID=YOUR_TELEGRAM_ID
echo ADMIN_SECRET=12345
echo ENCRYPTION_KEY=32bytehexkey32bytehexkey32bytehe
echo PORT=3000
) > backend\.env

:: prisma schema
(
echo generator client {
echo   provider = "prisma-client-js"
echo }
echo datasource db {
echo   provider = "sqlite"
echo   url      = env("DATABASE_URL")
echo }
echo model Deal {
echo   id                   String       @id @default(cuid())
echo   amount               Int
echo   commission           Int
echo   status               DealStatus   @default(CREATED)
echo   couponCodeEncrypted  String
echo   paymentDetails       String?
echo   createdAt            DateTime     @default(now())
echo   updatedAt            DateTime     @updatedAt
echo   buyerTelegramId      String
echo   sellerTelegramId     String?
echo   disputeReason        String?
echo   disputeCreatedAt     DateTime?
echo   buyerBlockedUntil    DateTime?
echo   fakePayCount         Int          @default(0)
echo   paymentDeadline      DateTime?
echo   messages             Message[]
echo }
echo model Message {
echo   id        String   @id @default(cuid())
echo   dealId    String
echo   deal      Deal     @relation(fields: [dealId], references: [id], onDelete: Cascade)
echo   fromId    String
echo   fromRole  String
echo   text      String
echo   isRead    Boolean  @default(false)
echo   createdAt DateTime @default(now())
echo }
echo model Setting {
echo   key   String @id
echo   value String
echo }
echo model FraudLog {
echo   id            Int      @id @default(autoincrement())
echo   buyerTelegramId String
echo   action        String
echo   createdAt     DateTime @default(now())
echo }
echo enum DealStatus {
echo   CREATED
echo   PENDING_PAYMENT
echo   WAITING_CONFIRMATION
echo   PAID
echo   COMPLETED
echo   DISPUTE
echo }
) > backend\prisma\schema.prisma

:: server.js (полная версия, сжатая но рабочая)
(
echo require('dotenv').config();
echo const express = require('express');
echo const path = require('path');
echo const cors = require('cors');
echo const crypto = require('crypto');
echo const { PrismaClient } = require('@prisma/client');
echo const TelegramBot = require('node-telegram-bot-api');
echo const prisma = new PrismaClient();
echo const app = express();
echo app.use(cors());
echo app.use(express.json());
echo app.use(express.static(path.join(__dirname, '..', 'frontend', 'dist')));
echo const botToken = process.env.TELEGRAM_BOT_TOKEN;
echo const adminChatId = process.env.ADMIN_CHAT_ID;
echo const bot = new TelegramBot(botToken, { polling: true });
echo const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY;
echo const IV_LENGTH = 16;
echo function encrypt(text) {
echo   const iv = crypto.randomBytes(IV_LENGTH);
echo   const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY, 'hex'), iv);
echo   let encrypted = cipher.update(text);
echo   encrypted = Buffer.concat([encrypted, cipher.final()]);
echo   return iv.toString('hex') + ':' + encrypted.toString('hex');
echo }
echo function decrypt(text) {
echo   const parts = text.split(':');
echo   const iv = Buffer.from(parts.shift(), 'hex');
echo   const encryptedText = Buffer.from(parts.join(':'), 'hex');
echo   const decipher = crypto.createDecipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY, 'hex'), iv);
echo   let decrypted = decipher.update(encryptedText);
echo   decrypted = Buffer.concat([decrypted, decipher.final()]);
echo   return decrypted.toString();
echo }
echo function calculateCommission(amount) {
echo   if (amount >= 1000 && amount < 2500) return 100;
echo   if (amount >= 2500 && amount < 5000) return 200;
echo   if (amount >= 5000 && amount < 8000) return 300;
echo   if (amount >= 8000 && amount <= 10000) return 500;
echo   if (amount > 10000) return Math.floor(amount * 0.05);
echo   return 0;
echo }
echo async function getCurrentPaymentDetails() {
echo   const setting = await prisma.setting.findUnique({ where: { key: 'payment_details' } });
echo   return setting?.value || null;
echo }
echo async function setPaymentDetails(details) {
echo   await prisma.setting.upsert({ where: { key: 'payment_details' }, update: { value: details }, create: { key: 'payment_details', value: details } });
echo }
echo async function isBuyerBlocked(buyerTelegramId) {
echo   const blocked = await prisma.deal.findFirst({ where: { buyerTelegramId, buyerBlockedUntil: { gt: new Date() } } });
echo   return !!blocked;
echo }
echo async function logFakePayClick(buyerTelegramId, dealId) {
echo   await prisma.fraudLog.create({ data: { buyerTelegramId, action: 'fake_pay_click' } });
echo   const lastHour = new Date(Date.now() - 60 * 60 * 1000);
echo   const clicks = await prisma.fraudLog.count({ where: { buyerTelegramId, action: 'fake_pay_click', createdAt: { gt: lastHour } } });
echo   if (clicks >= 3) {
echo     await prisma.deal.updateMany({ where: { buyerTelegramId, status: { in: ['CREATED', 'PENDING_PAYMENT'] } }, data: { buyerBlockedUntil: new Date(Date.now() + 60 * 60 * 1000) } });
echo     await bot.sendMessage(adminChatId, `⚠️ Пользователь ${buyerTelegramId} заблокирован на 1 час.`);
echo   }
echo   await prisma.deal.update({ where: { id: dealId }, data: { fakePayCount: { increment: 1 } } });
echo }
echo app.post('/api/deal/create', async (req, res) => {
echo   const { amount, couponCode, buyerTelegramId, sellerTelegramId } = req.body;
echo   if (!amount || !couponCode || !buyerTelegramId) return res.status(400).json({ error: 'Missing fields' });
echo   const commission = calculateCommission(amount);
echo   const encrypted = encrypt(couponCode);
echo   const deal = await prisma.deal.create({ data: { amount, commission, couponCodeEncrypted: encrypted, buyerTelegramId, sellerTelegramId: sellerTelegramId || null, status: 'CREATED' } });
echo   res.json({ dealId: deal.id });
echo });
echo app.get('/api/deal/:id', async (req, res) => {
echo   const deal = await prisma.deal.findUnique({ where: { id: req.params.id } });
echo   if (!deal) return res.status(404).json({ error: 'Not found' });
echo   let coupon = null;
echo   if (deal.status === 'PAID' || deal.status === 'COMPLETED') coupon = decrypt(deal.couponCodeEncrypted);
echo   let paymentDetails = deal.paymentDetails;
echo   if (!paymentDetails && deal.status === 'PENDING_PAYMENT') paymentDetails = await getCurrentPaymentDetails();
echo   res.json({ id: deal.id, amount: deal.amount, commission: deal.commission, status: deal.status, paymentDetails, couponCode: coupon, createdAt: deal.createdAt, buyerBlockedUntil: deal.buyerBlockedUntil, fakePayCount: deal.fakePayCount, paymentDeadline: deal.paymentDeadline, disputeReason: deal.disputeReason });
echo });
echo app.post('/api/deal/:id/initiate-payment', async (req, res) => {
echo   const deal = await prisma.deal.findUnique({ where: { id: req.params.id } });
echo   if (!deal) return res.status(404).json({ error: 'Deal not found' });
echo   if (deal.status !== 'CREATED') return res.status(400).json({ error: 'Invalid status' });
echo   if (await isBuyerBlocked(deal.buyerTelegramId)) return res.status(403).json({ error: 'Blocked' });
echo   const paymentDetails = await getCurrentPaymentDetails();
echo   if (!paymentDetails) return res.status(500).json({ error: 'No payment details' });
echo   const deadline = new Date(Date.now() + 10 * 60 * 1000);
echo   await prisma.deal.update({ where: { id: deal.id }, data: { status: 'PENDING_PAYMENT', paymentDetails, paymentDeadline: deadline } });
echo   res.json({ paymentDetails, deadline });
echo });
echo app.post('/api/deal/:id/mark-paid', async (req, res) => {
echo   const deal = await prisma.deal.findUnique({ where: { id: req.params.id } });
echo   if (!deal) return res.status(404).json({ error: 'Not found' });
echo   if (deal.status !== 'PENDING_PAYMENT') return res.status(400).json({ error: 'Invalid status' });
echo   if (deal.paymentDeadline && new Date() > new Date(deal.paymentDeadline)) {
echo     await prisma.deal.update({ where: { id: deal.id }, data: { status: 'CREATED', paymentDetails: null, paymentDeadline: null } });
echo     return res.status(400).json({ error: 'Deadline expired' });
echo   }
echo   await logFakePayClick(deal.buyerTelegramId, deal.id);
echo   await prisma.deal.update({ where: { id: deal.id }, data: { status: 'WAITING_CONFIRMATION' } });
echo   const keyboard = { inline_keyboard: [[{ text: '✅ Подтвердить', callback_data: `confirm_${deal.id}` }, { text: '❌ Отклонить', callback_data: `reject_${deal.id}` }]] };
echo   await bot.sendMessage(adminChatId, `💰 Заказ #${deal.id}\nСумма: ${deal.amount}₽\nПроверьте поступление.`, { reply_markup: keyboard });
echo   res.json({ status: 'WAITING_CONFIRMATION' });
echo });
echo app.post('/api/admin/confirm-transaction', async (req, res) => {
echo   const { dealId, adminSecret } = req.body;
echo   if (adminSecret !== process.env.ADMIN_SECRET) return res.status(403).json({ error: 'Unauthorized' });
echo   const deal = await prisma.deal.findUnique({ where: { id: dealId } });
echo   if (!deal || deal.status !== 'WAITING_CONFIRMATION') return res.status(400).json({ error: 'Invalid deal' });
echo   await prisma.deal.update({ where: { id: dealId }, data: { status: 'PAID' } });
echo   const coupon = decrypt(deal.couponCodeEncrypted);
echo   await bot.sendMessage(deal.buyerTelegramId, `✅ Сделка #${deal.id} оплачена! Ваш купон: ${coupon}`);
echo   res.json({ success: true });
echo });
echo app.post('/api/admin/reject-transaction', async (req, res) => {
echo   const { dealId, adminSecret } = req.body;
echo   if (adminSecret !== process.env.ADMIN_SECRET) return res.status(403).json({ error: 'Unauthorized' });
echo   const deal = await prisma.deal.findUnique({ where: { id: dealId } });
echo   if (!deal || deal.status !== 'WAITING_CONFIRMATION') return res.status(400).json({ error: 'Invalid deal' });
echo   await prisma.deal.update({ where: { id: dealId }, data: { status: 'CREATED', paymentDetails: null, paymentDeadline: null } });
echo   await bot.sendMessage(deal.buyerTelegramId, `❌ Сделка #${deal.id} отклонена администратором.`);
echo   res.json({ success: true });
echo });
echo app.post('/api/admin/set-payment-details', async (req, res) => {
echo   const { details, adminSecret } = req.body;
echo   if (adminSecret !== process.env.ADMIN_SECRET) return res.status(403).json({ error: 'Unauthorized' });
echo   await setPaymentDetails(details);
echo   res.json({ success: true });
echo });
echo app.post('/api/deal/:id/dispute', async (req, res) => {
echo   const { reason } = req.body;
echo   const deal = await prisma.deal.findUnique({ where: { id: req.params.id } });
echo   if (!deal) return res.status(404).json({ error: 'Not found' });
echo   if (deal.status !== 'PAID' && deal.status !== 'COMPLETED') return res.status(400).json({ error: 'Cannot dispute now' });
echo   await prisma.deal.update({ where: { id: deal.id }, data: { status: 'DISPUTE', disputeReason: reason, disputeCreatedAt: new Date() } });
echo   await bot.sendMessage(adminChatId, `⚠️ Спор по сделке #${deal.id}\nПричина: ${reason}`);
echo   res.json({ success: true });
echo });
echo app.get('/api/deal/:id/messages', async (req, res) => {
echo   const messages = await prisma.message.findMany({ where: { dealId: req.params.id }, orderBy: { createdAt: 'asc' } });
echo   res.json(messages);
echo });
echo app.post('/api/deal/:id/messages', async (req, res) => {
echo   const { fromId, text, fromRole } = req.body;
echo   const message = await prisma.message.create({ data: { dealId: req.params.id, fromId, text, fromRole } });
echo   const deal = await prisma.deal.findUnique({ where: { id: req.params.id } });
echo   const recipientId = fromRole === 'buyer' ? deal.sellerTelegramId : deal.buyerTelegramId;
echo   if (recipientId) bot.sendMessage(recipientId, `💬 Новое сообщение в сделке #${deal.id}: ${text}`);
echo   res.json(message);
echo });
echo app.get('/api/admin/deals', async (req, res) => {
echo   const deals = await prisma.deal.findMany({ orderBy: { createdAt: 'desc' }, take: 50 });
echo   res.json(deals);
echo });
echo app.get('*', (req, res) => {
echo   res.sendFile(path.join(__dirname, '..', 'frontend', 'dist', 'index.html'));
echo });
echo bot.on('callback_query', async (callbackQuery) => {
echo   const data = callbackQuery.data;
echo   const dealId = data.split('_')[1];
echo   const action = data.split('_')[0];
echo   const deal = await prisma.deal.findUnique({ where: { id: dealId } });
echo   if (!deal || deal.status !== 'WAITING_CONFIRMATION') {
echo     await bot.answerCallbackQuery(callbackQuery.id, { text: 'Сделка уже обработана', show_alert: true });
echo     return;
echo   }
echo   if (action === 'confirm') {
echo     await prisma.deal.update({ where: { id: dealId }, data: { status: 'PAID' } });
echo     const coupon = decrypt(deal.couponCodeEncrypted);
echo     await bot.sendMessage(deal.buyerTelegramId, `✅ Сделка #${dealId} оплачена! Купон: ${coupon}`);
echo     await bot.editMessageText(`✅ Сделка #${dealId} подтверждена`, { chat_id: callbackQuery.message.chat.id, message_id: callbackQuery.message.message_id });
echo   } else if (action === 'reject') {
echo     await prisma.deal.update({ where: { id: dealId }, data: { status: 'CREATED', paymentDetails: null, paymentDeadline: null } });
echo     await bot.sendMessage(deal.buyerTelegramId, `❌ Сделка #${dealId} отклонена.`);
echo     await bot.editMessageText(`❌ Сделка #${dealId} отклонена`, { chat_id: callbackQuery.message.chat.id, message_id: callbackQuery.message.message_id });
echo   }
echo   await bot.answerCallbackQuery(callbackQuery.id);
echo });
echo const PORT = process.env.PORT || 3000;
echo app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
) > backend\server.js

echo [4/9] Генерация фронтенда (React + Tailwind)...
:: frontend package.json
(
echo {
echo   "name": "myrka-frontend",
echo   "version": "1.0.0",
echo   "type": "module",
echo   "scripts": {
echo     "dev": "vite",
echo     "build": "vite build"
echo   },
echo   "dependencies": {
echo     "react": "^18.2.0",
echo     "react-dom": "^18.2.0",
echo     "react-router-dom": "^6.14.0"
echo   },
echo   "devDependencies": {
echo     "@vitejs/plugin-react": "^4.0.0",
echo     "autoprefixer": "^10.4.14",
echo     "postcss": "^8.4.24",
echo     "tailwindcss": "^3.3.2",
echo     "vite": "^4.3.9"
echo   }
echo }
) > frontend\package.json

:: vite.config.js
(
echo import { defineConfig } from 'vite';
echo import react from '@vitejs/plugin-react';
echo export default defineConfig({
echo   plugins: [react()],
echo   server: { port: 5173, proxy: { '/api': 'http://localhost:3000' } }
echo });
) > frontend\vite.config.js

:: tailwind.config.js
(
echo export default {
echo   content: ["./index.html", "./src/**/*.{js,jsx}"],
echo   theme: { extend: {} },
echo   plugins: []
echo };
) > frontend\tailwind.config.js

:: postcss.config.js
(
echo export default {
echo   plugins: { tailwindcss: {}, autoprefixer: {} }
echo };
) > frontend\postcss.config.js

:: index.html
(
echo ^<!DOCTYPE html^>
echo ^<html lang="ru"^>
echo ^<head^>
echo   ^<meta charset="UTF-8"^>
echo   ^<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no"^>
echo   ^<title^>Гарант Сервис | Myrka^</title^>
echo   ^<script src="https://telegram.org/js/telegram-web-app.js"^>^</script^>
echo ^</head^>
echo ^<body^>
echo   ^<div id="root"^>^</div^>
echo   ^<script type="module" src="/src/main.jsx"^>^</script^>
echo ^</body^>
echo ^</html^>
) > frontend\index.html

:: main.jsx
(
echo import React from 'react';
echo import ReactDOM from 'react-dom/client';
echo import App from './App';
echo import './index.css';
echo ReactDOM.createRoot(document.getElementById('root')).render(^<App /^>);
) > frontend\src\main.jsx

:: index.css
(
echo @tailwind base;
echo @tailwind components;
echo @tailwind utilities;
) > frontend\src\index.css

:: App.jsx (упрощённый, но рабочий)
(
echo import React from 'react';
echo import { BrowserRouter, Routes, Route } from 'react-router-dom';
echo import Layout from './components/Layout';
echo import DealScreen from './pages/DealScreen';
echo import PaymentScreen from './pages/PaymentScreen';
echo import SuccessScreen from './pages/SuccessScreen';
echo import DisputeScreen from './pages/DisputeScreen';
echo import ChatScreen from './pages/ChatScreen';
echo import AdminDashboard from './pages/AdminDashboard';
echo export default function App() {
echo   return (
echo     ^<BrowserRouter^>
echo       ^<Routes^>
echo         ^<Route path="/" element={^<Layout /^>}^>
echo           ^<Route index element={^<DealScreen /^>} /^>
echo           ^<Route path="payment/:dealId" element={^<PaymentScreen /^>} /^>
echo           ^<Route path="success/:dealId" element={^<SuccessScreen /^>} /^>
echo           ^<Route path="dispute/:dealId" element={^<DisputeScreen /^>} /^>
echo           ^<Route path="chat/:dealId" element={^<ChatScreen /^>} /^>
echo           ^<Route path="admin" element={^<AdminDashboard /^>} /^>
echo         ^</Route^>
echo       ^</Routes^>
echo     ^</BrowserRouter^>
echo   );
echo }
) > frontend\src\App.jsx

:: Создаём минимальные компоненты (чтобы не было ошибок импорта)
(
echo import React from 'react';
echo import { Outlet } from 'react-router-dom';
echo export default function Layout() { return ^<div className="min-h-screen bg-gray-900 text-white p-4"^>^<Outlet /^>^</div^>; }
) > frontend\src\components\Layout.jsx

(
echo import React from 'react';
echo export default function NeonCard({ children }) { return ^<div className="bg-gray-800 rounded-2xl p-5 shadow-lg"^>{children}^</div^>; }
) > frontend\src\components\NeonCard.jsx

(
echo import React from 'react';
echo export default function Button({ children, onClick, variant = 'primary', disabled = false }) {
echo   const bg = variant === 'primary' ? 'bg-blue-600' : 'bg-gray-600';
echo   return ^<button disabled={disabled} onClick={onClick} className={`w-full py-2 rounded-xl ${bg} disabled:opacity-50`}^>{children}^</button^>;
echo }
) > frontend\src\components\Button.jsx

:: Для остальных компонентов создаём заглушки (полные версии можно взять из предыдущих сообщений, но для запуска хватит)
(
echo import React, { useState, useEffect } from 'react';
echo import { useParams, useNavigate } from 'react-router-dom';
echo import NeonCard from '../components/NeonCard';
echo import Button from '../components/Button';
echo export default function DealScreen() {
echo   const navigate = useNavigate();
echo   const [amount, setAmount] = useState('');
echo   const [coupon, setCoupon] = useState('');
echo   const createDeal = async () => {
echo     const buyerId = window.Telegram?.WebApp?.initDataUnsafe?.user?.id || 'test';
echo     const res = await fetch('/api/deal/create', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ amount: parseInt(amount), couponCode: coupon, buyerTelegramId: buyerId }) });
echo     const data = await res.json();
echo     if (res.ok) navigate(`/payment/${data.dealId}`);
echo     else alert('Ошибка');
echo   };
echo   return ^<NeonCard^>^<input type="number" placeholder="Сумма" className="w-full p-2 mb-2 bg-gray-700 rounded" value={amount} onChange={e=>setAmount(e.target.value)} /^>^<input placeholder="Код купона" className="w-full p-2 mb-2 bg-gray-700 rounded" value={coupon} onChange={e=>setCoupon(e.target.value)} /^>^<Button onClick={createDeal}^>Создать сделку^</Button^>^</NeonCard^>;
echo }
) > frontend\src\pages\DealScreen.jsx

:: PaymentScreen (упрощённый, но рабочий)
(
echo import React, { useState, useEffect } from 'react';
echo import { useParams, useNavigate } from 'react-router-dom';
echo import NeonCard from '../components/NeonCard';
echo import Button from '../components/Button';
echo export default function PaymentScreen() {
echo   const { dealId } = useParams();
echo   const navigate = useNavigate();
echo   const [deal, setDeal] = useState(null);
echo   const [initiated, setInitiated] = useState(false);
echo   useEffect(() => { fetch(`/api/deal/${dealId}`).then(res=>res.json()).then(setDeal); }, []);
echo   const initiate = async () => { const res = await fetch(`/api/deal/${dealId}/initiate-payment`, { method: 'POST' }); if(res.ok){ setInitiated(true); fetch(`/api/deal/${dealId}`).then(res=>res.json()).then(setDeal); } else alert('Ошибка'); };
echo   const markPaid = async () => { await fetch(`/api/deal/${dealId}/mark-paid`, { method: 'POST' }); alert('Ожидайте подтверждения'); };
echo   if (!deal) return ^<div^>Загрузка...^</div^>;
echo   if (deal.status === 'PAID') navigate(`/success/${dealId}`);
echo   return ^<div^>^<NeonCard^>Сумма: {deal.amount}₽ + комиссия {deal.commission}₽^</NeonCard^>{!initiated ? ^<Button onClick={initiate}^>Оплатить^</Button^> : ^<^>^<NeonCard^>Реквизиты: {deal.paymentDetails}^<Button onClick={()=>navigator.clipboard.writeText(deal.paymentDetails)}^>Скопировать^</Button^>^</NeonCard^>^<Button onClick={markPaid}^>Я оплатил^</Button^>^</^>}^</div^>;
echo }
) > frontend\src\pages\PaymentScreen.jsx

:: Остальные страницы – заглушки для запуска (можно потом заменить на полные)
echo export default function SuccessScreen() { return ^<div^>Сделка завершена^</div^>; } > frontend\src\pages\SuccessScreen.jsx
echo export default function DisputeScreen() { return ^<div^>Спор открыт^</div^>; } > frontend\src\pages\DisputeScreen.jsx
echo export default function ChatScreen() { return ^<div^>Чат сделки^</div^>; } > frontend\src\pages\ChatScreen.jsx
echo export default function AdminDashboard() { return ^<div^>Админ панель^</div^>; } > frontend\src\pages\AdminDashboard.jsx
echo export default function StatusBar() { return ^<div^>Myrka^</div^>; } > frontend\src\components\StatusBar.jsx
echo export default function Timer() { return ^<div^>Таймер^</div^>; } > frontend\src\components\Timer.jsx

echo [5/9] Установка зависимостей backend...
cd backend
call npm install --silent
if %errorlevel% neq 0 ( echo Ошибка npm install backend & pause & exit /b 1 )
call npx prisma generate
call npx prisma migrate dev --name init --skip-seed
cd ..

echo [6/9] Установка зависимостей frontend...
cd frontend
call npm install --silent
if %errorlevel% neq 0 ( echo Ошибка npm install frontend & pause & exit /b 1 )
call npm run build
cd ..

echo [7/9] Запуск сервисов...
start "Myrka Backend" cmd /c "cd backend && npm start > ..\logs\backend.log 2>&1"
timeout /t 3 /nobreak >nul
start "Myrka Frontend" cmd /c "cd frontend && npm run dev > ..\logs\frontend.log 2>&1"

echo [8/9] Проверка работы...
timeout /t 2 /nobreak >nul
curl -s http://localhost:3000 >nul
if %errorlevel% equ 0 ( echo Бэкенд доступен на http://localhost:3000 ) else ( echo Бэкенд не запустился, проверьте logs\backend.log )
curl -s http://localhost:5173 >nul
if %errorlevel% equ 0 ( echo Фронтенд доступен на http://localhost:5173 ) else ( echo Фронтенд не запустился, проверьте logs\frontend.log )

echo [9/9] Готово!
echo.
echo Открой в браузере: http://localhost:3000
echo Для остановки закройте окна "Myrka Backend" и "Myrka Frontend"
echo.
pause