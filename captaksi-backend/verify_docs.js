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
                try {
                    resolve({ status: res.statusCode, body: JSON.parse(data) });
                } catch (e) {
                    resolve({ status: res.statusCode, body: data });
                }
            });
        });

        req.on('error', (e) => reject(e));

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

async function verifyDocs() {
    console.log('--- Verifying Documents ---');

    // 1. Login
    let token;
    try {
        const res = await makeRequest('/login', 'POST', { email: 'admin@alibinali.com', sifre: '123456' });
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

    // 2. Get Driver Details
    try {
        console.log('Listing drivers to find an ID...');
        const driversRes = await makeRequest('/drivers', 'GET', null, token);
        if (driversRes.status === 200 && driversRes.body.length > 0) {
            const driverId = driversRes.body[0].id;
            console.log(`Found driver ID: ${driverId}. Fetching details...`);

            const detailRes = await makeRequest(`/drivers/${driverId}`, 'GET', null, token);
            if (detailRes.status === 200) {
                console.log('✅ Driver Details received.');
                if (detailRes.body.documents) {
                    console.log('📄 Driver Documents:', detailRes.body.documents);
                } else {
                    console.error('❌ Driver Documents field missing!');
                }
            } else {
                console.error('❌ Failed to get driver details:', detailRes.status);
            }

        } else {
            console.warn('⚠️ No drivers found to test.');
        }

    } catch (err) {
        console.error('Driver Test error:', err);
    }

    // 3. Get User Details
    try {
        console.log('Listing users to find an ID...');
        const usersRes = await makeRequest('/users', 'GET', null, token);
        if (usersRes.status === 200 && usersRes.body.length > 0) {
            const userId = usersRes.body[0].id;
            console.log(`Found user ID: ${userId}. Fetching details...`);

            const detailRes = await makeRequest(`/users/${userId}/details`, 'GET', null, token);
            if (detailRes.status === 200) {
                console.log('✅ User Details received.');
                if (detailRes.body.documents) {
                    console.log('📄 User Documents:', detailRes.body.documents);
                } else {
                    console.error('❌ User Documents field missing!');
                }
            } else {
                console.error('❌ Failed to get user details:', detailRes.status);
            }

        } else {
            console.warn('⚠️ No users found to test.');
        }

    } catch (err) {
        console.error('User Test error:', err);
    }
}

verifyDocs();
