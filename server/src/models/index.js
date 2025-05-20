const sequelize = require('../config/db');
const User = require('./user');

// Sync all models at once (creates tables in MySQL if they don’t exist)
sequelize.sync()
  .then(() => console.log('All models were synchronized successfully.'))
  .catch(err => console.log('Error syncing models:', err));

module.exports = { User };
