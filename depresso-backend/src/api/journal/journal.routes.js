const express = require('express');
const router = express.Router();
const controller = require('./journal.controller');

// Journal Entries
router.post('/entries', controller.createEntry);
router.get('/entries', controller.getEntriesForUser);

// AI Chat Messages
router.post('/entries/:entryId/messages', controller.addMessageToEntry);
router.get('/entries/:entryId/messages', controller.getMessagesForEntry);

module.exports = router;
