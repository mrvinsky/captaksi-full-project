
const fs = require('fs');
const path = require('path');

// Note: In Node v25, fetch and FormData are global.

const BASE_URL = 'http://127.0.0.1:3000/api';
const ASSETS_DIR = path.join(__dirname, 'test_assets');
const OUTPUT_FILE = path.join(__dirname, '..', 'new driver and rider tokens.txt');

async function runTest() {
    const timestamp = Date.now();
    const userData = {
        ad: `TestAd_${timestamp}`,
        soyad: `TestSoyad_${timestamp}`,
        telefon_numarasi: `555${String(timestamp).slice(-7)}`,
        email: `test_${timestamp}@example.com`,
        sifre: 'password123'
    };

    console.log('🚀 Starting Registration Test...');
    console.log('User Data:', userData);

    // 1. REGISTER
    const formData = new FormData();
    formData.append('ad', userData.ad);
    formData.append('soyad', userData.soyad);
    formData.append('telefon_numarasi', userData.telefon_numarasi);
    formData.append('email', userData.email);
    formData.append('sifre', userData.sifre);

    // Attach files
    const profileBlob = new Blob([fs.readFileSync(path.join(ASSETS_DIR, 'dummy_profile.jpg'))], { type: 'image/jpeg' });
    const recordBlob = new Blob([fs.readFileSync(path.join(ASSETS_DIR, 'dummy_record.pdf'))], { type: 'application/pdf' });

    formData.append('profileImage', profileBlob, 'dummy_profile.jpg');
    formData.append('criminalRecord', recordBlob, 'dummy_record.pdf');

    try {
        console.log('📤 Sending Registration Request...');
        const regRes = await fetch(`${BASE_URL}/users/register`, {
            method: 'POST',
            body: formData,
        });

        if (!regRes.ok) {
            const err = await regRes.text();
            throw new Error(`Registration Failed: ${regRes.status} ${err}`);
        }

        const regJson = await regRes.json();
        console.log('✅ Registration Successful!');
        const token = regJson.token;
        console.log('🔑 Token received:', token.substring(0, 15) + '...');

        // 2. VERIFY DB PERSISTENCE (GET PROFILE)
        console.log('🔍 Verifying Persistence (Get Profile)...');
        const meRes = await fetch(`${BASE_URL}/users/me`, {
            headers: { 'x-auth-token': token }
        });

        if (!meRes.ok) {
            throw new Error(`Get Profile Failed: ${meRes.status}`);
        }

        const meJson = await meRes.json();
        if (meJson.email === userData.email) {
            console.log('✅ Persistence Verified: Email matches.');
        } else {
            throw new Error('Persistence Mismatch: Email does not match.');
        }

        // 3. LOGIN (Double Check)
        console.log('🔄 Testing Login...');
        const loginRes = await fetch(`${BASE_URL}/users/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: userData.email, sifre: userData.sifre })
        });

        if (!loginRes.ok) {
            throw new Error(`Login Failed: ${loginRes.status}`);
        }
        console.log('✅ Login Successful!');

        // 4. SAVE CREDENTIALS
        const logEntry = `
--------------------------------------------------
USER TYPE: RIDER (Test Automation)
DATE: ${new Date().toISOString()}
EMAIL: ${userData.email}
PASSWORD: ${userData.sifre}
PHONE: ${userData.telefon_numarasi}
TOKEN: ${token}
--------------------------------------------------
`;
        fs.appendFileSync(OUTPUT_FILE, logEntry);
        console.log(`💾 Credentials saved to: ${OUTPUT_FILE}`);

    } catch (error) {
        console.error('❌ TEST FAILED:', error);
        process.exit(1);
    }
}

runTest();
