const express = require('express');
const router = express.Router();
const controller = require('./wellness.controller');

// Get all available tasks
router.get('/tasks', controller.getAllTasks);

// Get tasks for a specific user
router.get('/user-tasks', controller.getUserTasks);

// Assign a task to a user
router.post('/user-tasks', controller.createUserTask);

// Mark a user's task as complete
router.put('/user-tasks/:userTaskId', controller.completeUserTask);

module.exports = router;
