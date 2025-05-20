const { User } = require('../models');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const haversine = require('haversine-distance'); // npm i haversine-distance

// Signup
exports.createUser = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      email,
      phone,
      password: hashedPassword,
    });

    res.status(201).json({ message: 'User created successfully', user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Login
exports.loginUser = async (req, res) => {
  try {
    const { email, password, latitude, longitude } = req.body;

    const user = await User.findOne({ where: { email } });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Save login location
    user.login_latitude = latitude;
    user.login_longitude = longitude;
    await user.save();

    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: '1d',
    });

    res.json({ message: 'Login successful', token, user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get user
exports.getUser = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.logoutUser = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const userId = req.user.id;

    const user = await User.findByPk(userId);
    if (!user || !user.login_latitude || !user.login_longitude) {
      return res.status(400).json({ message: 'Login location not recorded.' });
    }

    const loginCoords = { lat: user.login_latitude, lon: user.login_longitude };
    const logoutCoords = { lat: latitude, lon: longitude };

    const distance = haversine(loginCoords, logoutCoords); // distance in meters

    if (distance > 50) {
      return res.status(403).json({ message: 'Logout allowed only within 50 meters of login location.' });
    }

    return res.json({ message: 'Logout successful.' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};