const express = require('express');
const router = express.Router();
const controller = require('./metrics.controller');

router.post('/submit', controller.submitMetrics);

module.exports = router;
