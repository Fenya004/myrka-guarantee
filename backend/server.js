const express = require('express');
const path = require('path');
const app = express();
const PORT = 3000;

// Раздаём статические файлы из папки frontend/dist
app.use(express.static(path.join(__dirname, '..', 'frontend', 'dist')));

// API-маршруты (если есть другие – добавьте их сюда)
app.get('/api/status', (req, res) => {
  res.json({ status: 'ok' });
});

// ВАЖНО: Все остальные GET-запросы направляем на index.html (для React Router)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'frontend', 'dist', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});