const pool = require('../../config/db');

exports.submitMetrics = async (req, res) => {
    const { userId, dailyMetrics, typingMetrics, motionMetrics } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        if (dailyMetrics) {
            const { steps, activeEnergy, heartRate } = dailyMetrics;
            await client.query(
                'INSERT INTO DailyMetrics (user_id, steps, active_energy, heart_rate) VALUES ($1, $2, $3, $4)',
                [userId, steps, activeEnergy, heartRate]
            );
        }

        if (typingMetrics) {
            const { wordsPerMinute, totalEditCount } = typingMetrics;
            await client.query(
                'INSERT INTO TypingMetrics (user_id, words_per_minute, total_edit_count) VALUES ($1, $2, $3)',
                [userId, wordsPerMinute, totalEditCount]
            );
        }

        if (motionMetrics) {
            const { avgAccelerationX, avgAccelerationY, avgAccelerationZ } = motionMetrics;
            await client.query(
                'INSERT INTO MotionMetrics (user_id, avg_acceleration_x, avg_acceleration_y, avg_acceleration_z) VALUES ($1, $2, $3, $4)',
                [userId, avgAccelerationX, avgAccelerationY, avgAccelerationZ]
            );
        }

        await client.query('COMMIT');
        res.status(201).send('Metrics submitted successfully.');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error submitting metrics:', error);
        res.status(500).send('Server error');
    } finally {
        client.release();
    }
};