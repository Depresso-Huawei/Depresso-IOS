const express = require('express');
const router = express.Router();
const controller = require('./support.controller');

// Get all available support resources
router.get('/resources', controller.getAllResources);

module.exports = router;
