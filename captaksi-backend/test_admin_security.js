const axios = require('axios');

async function testSecurity() {
    const baseUrl = 'http://localhost:3000/api/admin';

    console.log('--- Testing Security ---');

    // 1. Unprotected Access (Should Fail)
    try {
        console.log('testing unprotected access to /stats...');
        await axios.get(`${baseUrl}/stats`);
        console.error('❌ FAILED: Accessed /stats without token!');
    } catch (err) {
        if (err.response && (err.response.status === 401 || err.response.status === 403)) {
            console.log('✅ PASSED: Access denied as expected.');
        } else {
            console.error('❌ FAILED: Unexpected error:', err.message);
        }
    }

    // 2. Login
    let token;
    try {
        console.log('Logging in...');
        const res = await axios.post(`${baseUrl}/login`, {
            email: 'admin@captaksi.com',
            sifre: '123456'
        });
        token = res.data.token;
        console.log('✅ Login successful, token received.');
    } catch (err) {
        console.error('❌ Login failed:', err.message);
        return;
    }

    // 3. Protected Access (Should Pass)
    try {
        console.log('Testing protected access to /stats WITH token...');
        const res = await axios.get(`${baseUrl}/stats`, {
            headers: { 'x-auth-token': token }
        });
        console.log('✅ PASSED: Accessed /stats successfully.');
        console.log('Stats:', res.data);
    } catch (err) {
        console.error('❌ FAILED to access with token:', err.message);
    }
}

testSecurity();
