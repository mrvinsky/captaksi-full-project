// Native http module usage
// Or I can just use a simple http request using 'http' module to be dependency-free.

const http = require('http');

const RIDER_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7ImlkIjoxMX0sImlhdCI6MTc2ODcxNzEzOCwiZXhwIjoxNzY4NzM1MTM4fQ.opwBHnhjuIJz-zV9YzE7TaBCTFi46QvQNnhOfeh1qPM";

const postData = JSON.stringify({
    origin: {
        latitude: 37.4669983,
        longitude: -122.084
    },
    destination: {
        latitude: 37.5749983,
        longitude: -122.084
    },
    originAddress: "5km Kuzey Sapağı, Mountain View",
    destinationAddress: "12km İlerisi, Palo Alto civarı",
    vehicleTypeId: 1, // Standart
    estimatedFare: 150.0
});

const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/rides',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'x-auth-token': RIDER_TOKEN
    }
};

const req = http.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
    res.setEncoding('utf8');
    res.on('data', (chunk) => {
        console.log(`BODY: ${chunk}`);
    });
    res.on('end', () => {
        console.log('No more data in response.');
    });
});

req.on('error', (e) => {
    console.error(`problem with request: ${e.message}`);
});

// Write data to request body
req.write(postData);
req.end();
