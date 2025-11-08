const pool = require('../../config/db');

// Get all available wellness tasks
exports.getAllTasks = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM WellnessTasks');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching wellness tasks:', error);
        res.status(500).send('Server error');
    }
};

// Get all tasks for a specific user
exports.getUserTasks = async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).send('userId query parameter is required.');
    }

    try {
        const result = await pool.query(
            `SELECT ut.id, ut.completed_at, wt.title, wt.description
             FROM UserTasks ut
             JOIN WellnessTasks wt ON ut.task_id = wt.id
             WHERE ut.user_id = $1`,
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching user tasks:', error);
        res.status(500).send('Server error');
    }
};

// Assign a task to a user
exports.createUserTask = async (req, res) => {
    const { userId, taskId } = req.body;

    if (!userId || !taskId) {
        return res.status(400).send('userId and taskId are required.');
    }

    try {
        const result = await pool.query(
            'INSERT INTO UserTasks (user_id, task_id) VALUES ($1, $2) RETURNING *',
            [userId, taskId]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating user task:', error);
        res.status(500).send('Server error');
    }
};

// Mark a user's task as complete
exports.completeUserTask = async (req, res) => {
    const { userTaskId } = req.params;

    try {
        const result = await pool.query(
            'UPDATE UserTasks SET completed_at = NOW() WHERE id = $1 RETURNING *',
            [userTaskId]
        );

        if (result.rows.length === 0) {
            return res.status(404).send('User task not found.');
        }

        res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error('Error completing user task:', error);
        res.status(500).send('Server error');
    }
};