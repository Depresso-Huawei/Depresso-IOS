const pool = require('../../config/db');
const axios = require('axios');

// Correct Endpoint URL from HuaweiCredentials.swift
const QWEN_API_URL = 'https://api-ap-southeast-1.modelarts-maas.com/v1/chat/completions';

// Create a new journal entry
exports.createEntry = async (req, res) => {
    const { userId, title, content } = req.body;

    if (!userId) {
        return res.status(400).send('userId is required.');
    }

    try {
        const result = await pool.query(
            'INSERT INTO JournalEntries (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
            [userId, title, content]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating journal entry:', error);
        res.status(500).send('Server error');
    }
};

// Get all journal entries for a specific user
exports.getEntriesForUser = async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).send('userId query parameter is required.');
    }

    try {
        const result = await pool.query(
            'SELECT * FROM JournalEntries WHERE user_id = $1 ORDER BY created_at DESC',
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching journal entries:', error);
        res.status(500).send('Server error');
    }
};

// Add a chat message to a journal entry and get AI response
exports.addMessageToEntry = async (req, res) => {
    const { entryId } = req.params;
    const { userId, sender, content } = req.body;

    if (!userId || !sender || !content) {
        return res.status(400).send('userId, sender, and content are required.');
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // 1. Save the user's message
        await client.query(
            'INSERT INTO AIChatMessages (entry_id, user_id, sender, content) VALUES ($1, $2, $3, $4)',
            [entryId, userId, sender, content]
        );

        // 2. Fetch conversation history
        const history = await client.query(
            'SELECT sender, content FROM AIChatMessages WHERE entry_id = $1 ORDER BY created_at ASC',
            [entryId]
        );

        // Map roles: 'user' -> 'user', 'ai' -> 'assistant'
        const messages = history.rows.map(msg => ({
            role: msg.sender === 'ai' ? 'assistant' : 'user',
            content: msg.content
        }));

        // 3. Call the Huawei/Qwen API
        const qwenResponse = await axios.post(QWEN_API_URL, {
            model: 'qwen3-32b', // Correct model name
            messages: messages      // Correct request structure
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.QWEN_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        const aiContent = qwenResponse.data.choices[0]?.message?.content.trim();

        if (!aiContent) {
            throw new Error('Invalid AI response format');
        }

        // 4. Save AI's response with 'assistant' role
        const aiMessageResult = await client.query(
            'INSERT INTO AIChatMessages (entry_id, user_id, sender, content) VALUES ($1, $2, $3, $4) RETURNING *',
            [entryId, userId, 'assistant', aiContent]
        );

        await client.query('COMMIT');

        // 5. Send AI's response back to the client
        res.status(201).json(aiMessageResult.rows[0]);

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error processing AI chat message:', error.response ? error.response.data : error.message);
        res.status(500).send('Server error');
    } finally {
        client.release();
    }
};

// Get all messages for a specific journal entry
exports.getMessagesForEntry = async (req, res) => {
    const { entryId } = req.params;

    try {
        const result = await pool.query(
            'SELECT * FROM AIChatMessages WHERE entry_id = $1 ORDER BY created_at ASC',
            [entryId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error('Error fetching messages for entry:', error);
        res.status(500).send('Server error');
    }
};