const http = require('http');

function makeRequest(path, method, body, token) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: '/api/admin' + path,
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        if (token) {
            options.headers['x-auth-token'] = token;
        }

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                resolve({ status: res.statusCode, body: data ? JSON.parse(data) : {} });
            });
        });

        req.on('error', (e) => reject(e));

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

async function testSecurity() {
    console.log('--- Testing Security (Native HTTP) ---');

    // 1. Unprotected Access
    try {
        console.log('Testing unprotected access to /stats...');
        const res = await makeRequest('/stats', 'GET');
        if (res.status === 401 || res.status === 403) {
            console.log('✅ PASSED: Access denied as expected (Status:', res.status, ')');
        } else {
            console.error('❌ FAILED: Status:', res.status);
        }
    } catch (err) {
        console.error('Test error:', err);
    }

    // 2. Login
    let token;
    try {
        console.log('Logging in...');
        const res = await makeRequest('/login', 'POST', { email: 'admin@captaksi.com', sifre: '123456' });
        if (res.status === 200) {
            token = res.body.token;
            console.log('✅ Login successful.');
        } else {
            console.error('❌ Login failed:', res.status);
            return;
        }
    } catch (err) {
        console.error('Login error:', err);
        return;
    }

    // 3. Protected Access
    try {
        console.log('Testing protected access to /stats WITH token...');
        const res = await makeRequest('/stats', 'GET', null, token);
        if (res.status === 200) {
            console.log('✅ PASSED: Access successful.');
            console.log('Stats:', res.body);
        } else {
            console.error('❌ FAILED: Status:', res.status);
        }
    } catch (err) {
        console.error('Test error:', err);
    }
}

testSecurity();
