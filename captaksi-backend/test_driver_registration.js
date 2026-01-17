
const fs = require('fs');
const path = require('path');

// Note: In Node v25, fetch and FormData are global.

const BASE_URL = 'http://127.0.0.1:3000/api';
const ASSETS_DIR = path.join(__dirname, 'test_assets');
const OUTPUT_FILE = path.join(__dirname, '..', 'new driver and rider tokens.txt');

async function runTest() {
    const timestamp = Date.now();
    // Driver Info
    const userData = {
        ad: `DriverAd_${timestamp}`,
        soyad: `DriverSoyad_${timestamp}`,
        telefon_numarasi: `555${String(timestamp).slice(-7)}`,
        email: `driver_${timestamp}@example.com`,
        sifre: 'driver123'
    };

    console.log('🚀 Starting Driver Registration Test...');
    console.log('Driver Data:', userData);

    // 1. REGISTER
    const formData = new FormData();
    formData.append('ad', userData.ad);
    formData.append('soyad', userData.soyad);
    formData.append('telefon_numarasi', userData.telefon_numarasi);
    formData.append('email', userData.email);
    formData.append('sifre', userData.sifre);

    // Attach files
    // Ensure these files exist in test_assets
    try {
        const profileBlob = new Blob([fs.readFileSync(path.join(ASSETS_DIR, 'dummy_profile.jpg'))], { type: 'image/jpeg' });
        const recordBlob = new Blob([fs.readFileSync(path.join(ASSETS_DIR, 'dummy_record.pdf'))], { type: 'application/pdf' });

        formData.append('profileImage', profileBlob, 'dummy_profile.jpg');
        formData.append('criminalRecord', recordBlob, 'dummy_record.pdf');
    } catch (e) {
        console.warn("⚠️ Warning: Could not load test assets. Sending without files if backend allows, or failing.");
        // If backend requires them, this will fail. Let's proceed and see.
        console.error(e);
    }

    try {
        console.log('📤 Sending Registration Request to /drivers/register...');
        const regRes = await fetch(`${BASE_URL}/drivers/register`, {
            method: 'POST',
            body: formData,
        });

        if (!regRes.ok) {
            const err = await regRes.text();
            throw new Error(`Registration Failed: ${regRes.status} ${err}`);
        }

        const regJson = await regRes.json();
        console.log('✅ Registration Successful!');
        // Driver registration might not return a token if approval is needed?
        // Let's check the response. ApiService says: "Kayıt başarılı." if status 201.
        // It does NOT login immediately in ApiService.registerDriver.
        // But we want to login to get the token.

        console.log('Response:', regJson);

        // 2. LOGIN
        console.log('🔄 Testing Login...');
        const loginRes = await fetch(`${BASE_URL}/drivers/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: userData.email, sifre: userData.sifre })
        });

        if (!loginRes.ok) {
            const err = await loginRes.text();
            throw new Error(`Login Failed: ${loginRes.status} ${err}`);
        }

        const loginJson = await loginRes.json();
        const token = loginJson.token;
        console.log('✅ Login Successful!');
        console.log('🔑 Token received:', token ? token.substring(0, 15) + '...' : 'NONE');

        // 3. VERIFY PROFILE
        if (token) {
            console.log('🔍 Verifying Driver Profile...');
            const meRes = await fetch(`${BASE_URL}/drivers/me`, {
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
        }

        // 4. SAVE CREDENTIALS
        const logEntry = `
--------------------------------------------------
USER TYPE: DRIVER (Test Automation)
DATE: ${new Date().toISOString()}
EMAIL: ${userData.email}
PASSWORD: ${userData.sifre}
PHONE: ${userData.telefon_numarasi}
TOKEN: ${token || "LOGIN_FAILED_OR_PENDING_APPROVAL"}
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
