const express = require('express');
const path = require('path');
const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'frontend', 'dist')));

// Здесь ваши API маршруты (create, get, initiate, mark-paid и т.д.)

// Отдача HTML для корня (опционально)
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'frontend', 'dist', 'index.html'));
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Server on port ${PORT}`));