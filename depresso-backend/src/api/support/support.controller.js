const pool = require('../../config/db');

// Get all available support resources
exports.getAllResources = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM SupportResources');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching support resources:', error);
        res.status(500).send('Server error');
    }
};