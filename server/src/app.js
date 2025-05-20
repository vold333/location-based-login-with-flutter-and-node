const express = require('express');
const cors = require('cors');
const userRoutes = require('./routes/userRoutes');

const app = express();

app.use(cors());

// Middleware to parse JSON bodies
app.use(express.json());

// Routes
app.use('/users', userRoutes);


// Error handling middleware (if no route matches)
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: err.message || 'Something went wrong!' });
});

module.exports = app;
