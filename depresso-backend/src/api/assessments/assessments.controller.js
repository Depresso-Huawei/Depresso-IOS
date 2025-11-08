const pool = require('../../config/db');

exports.submitAssessment = async (req, res) => {
    const { userId, assessmentType, score, answers } = req.body;

    if (!userId || !assessmentType || score === undefined) {
        return res.status(400).send('userId, assessmentType, and score are required.');
    }

    try {
        const result = await pool.query(
            'INSERT INTO Assessments (user_id, assessment_type, score, answers) VALUES ($1, $2, $3, $4) RETURNING *',
            [userId, assessmentType, score, JSON.stringify(answers) || null]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error submitting assessment:', error);
        res.status(500).send('Server error');
    }
};