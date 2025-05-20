
const express = require('express');
const userController = require('../controllers/userController');
const authenticateToken = require('../middleware/authMiddleware');

const router = express.Router();

// Login route (No authentication needed for login)
router.post('/login', userController.loginUser);

router.get('/:id', authenticateToken, userController.getUser);  

router.post('/create', userController.createUser);

router.post('/logout', authenticateToken, userController.logoutUser);


module.exports = router;
