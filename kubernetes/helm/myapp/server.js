const express = require('express');
const app = express();
app.use(express.json());

const todos = [];
app.get('/health', (req, res) => res.status(200).json({ status: 'OK' }));
app.get('/todos', (req, res) => res.json(todos));
app.post('/todos', (req, res) => {
  todos.push({ id: todos.length + 1, ...req.body });
  res.status(201).json({ message: 'Todo created' });
});

app.listen(3000, () => console.log('Todo API running on port 3000'));
