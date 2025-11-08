const express = require('express');
const router = express.Router();
const controller = require('./assessments.controller');

router.post('/', controller.submitAssessment);

module.exports = router;
