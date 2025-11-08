const pool = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

exports.register = async (req, res) => {
    const newUserId = uuidv4();
    try {
        await pool.query('INSERT INTO Users (id) VALUES ($1)', [newUserId]);
        res.status(201).json({ userId: newUserId });
    } catch (error) {
        console.error('Error registering new user:', error);
        res.status(500).send('Server error');
    }
};