const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

// PayTR Token Al (Ödeme ekranını iFrame'de açmak için)
router.post('/paytr/token', paymentController.getPaymentToken);

// PayTR Webhook Callback (PayTR'nin ödeme sonucunu bize ilettiği asenkron uç)
// Not: PayTR buraya POST atar. CSRF falan olmamalı.
router.post('/paytr/callback', paymentController.paymentCallback);

module.exports = router;
