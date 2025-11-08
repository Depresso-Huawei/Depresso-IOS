const pool = require('../../config/db');

exports.getAllPosts = async (req, res) => {
    try {
        const result = await pool.query('SELECT id, title, content, like_count, created_at FROM CommunityPosts ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching posts:', error);
        res.status(500).send('Server error');
    }
};

exports.createPost = async (req, res) => {
    const { userId, title, content } = req.body;

    if (!userId || !content) {
        return res.status(400).send('userId and content are required.');
    }

    try {
        const result = await pool.query(
            'INSERT INTO CommunityPosts (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
            [userId, title, content]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating post:', error);
        res.status(500).send('Server error');
    }
};

exports.likePost = async (req, res) => {
    const { postId } = req.params;
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const insertResult = await client.query(
            'INSERT INTO PostLikes (user_id, post_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, postId]
        );

        if (insertResult.rowCount > 0) {
            await client.query(
                'UPDATE CommunityPosts SET like_count = like_count + 1 WHERE id = $1',
                [postId]
            );
        }

        await client.query('COMMIT');
        res.status(200).send('Post liked successfully.');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error liking post:', error);
        res.status(500).send('Server error');
    } finally {
        client.release();
    }
};

exports.unlikePost = async (req, res) => {
    const { postId } = req.params;
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const deleteResult = await client.query(
            'DELETE FROM PostLikes WHERE user_id = $1 AND post_id = $2',
            [userId, postId]
        );

        if (deleteResult.rowCount > 0) {
            await client.query(
                'UPDATE CommunityPosts SET like_count = like_count - 1 WHERE id = $1 AND like_count > 0',
                [postId]
            );
        }

        await client.query('COMMIT');
        res.status(200).send('Post unliked successfully.');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error unliking post:', error);
        res.status(500).send('Server error');
    } finally {
        client.release();
    }
};