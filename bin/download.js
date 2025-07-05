const https = require("https");
const http = require('http');
const fs = require('fs');
const { URL } = require('url');

const url = process.argv[2];
const filename = process.argv[3];

if (!url || !filename) {
    console.error("Usage: node download.js <url> <filename>");
    process.exit(1);
}

if (fs.existsSync(filename)) {
    console.log(filename + " already exists.");
    process.exit(0);
}

console.log("Downloading " + url);

const file = fs.createWriteStream(filename);
const protocol = url.startsWith("https") ? https : http;

protocol.get(url, (resp) => {
        if (resp.statusCode === 200) {
            const contentLength = resp.headers['content-length'];
            if (contentLength) console.log('Size: ' + contentLength + ' bytes');

            resp.pipe(file);

            file.on("finish", () => {
                file.close(() => {
                        process.exit(0);
                });
            });
        } else {
            console.error("Failed. HTTP Status: " + resp.statusCode);
            fs.unlinkSync(filename);
            process.exit(1);
        }
}).on("error", (err) => {
    console.error("Error: ", err.message);
    process.exit(1);
});
