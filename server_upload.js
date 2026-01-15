/**
 * DiscordScreen - Server JS Helper
 */

const https = require('https');
const url = require('url');

console.log('^3[DiscordScreen] JS Uploader loaded.^7');

on('DiscordScreen:executeJS_Upload', (webhookUrl, base64Data, embedJson) => {
    if (!webhookUrl || webhookUrl.includes("YOUR_WEBHOOK")) return;

    try {
        const base64Image = base64Data.replace(/^data:image\/[a-z]+;base64,/, "");
        const imageBuffer = Buffer.from(base64Image, 'base64');
        const boundary = '----TeamSnailyBoundary' + Date.now();
        
        let payload = [];
        payload.push(Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="payload_json"\r\n\r\n${JSON.stringify({ embeds: [embedJson] })}\r\n`));
        payload.push(Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="screenshot.jpg"\r\nContent-Type: image/jpeg\r\n\r\n`));
        payload.push(imageBuffer);
        payload.push(Buffer.from(`\r\n--${boundary}--\r\n`));

        const bodyBuffer = Buffer.concat(payload);
        const parsedUrl = url.parse(webhookUrl);

        const req = https.request({
            hostname: parsedUrl.hostname,
            path: parsedUrl.path,
            method: 'POST',
            headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}`, 'Content-Length': bodyBuffer.length }
        }, (res) => {
            // FIX: We accepteren nu 200 én 204 als succes, dus geen spam meer.
            if (res.statusCode === 200 || res.statusCode === 204) {
               // console.log(`^2[DiscordScreen] Upload Success!^7`); // Uncomment als je toch een bevestiging wilt
            } else {
                console.log(`^1[DiscordScreen] Error: Discord returned status ${res.statusCode}^7`);
                res.on('data', d => process.stdout.write(d)); // Print alleen error details
            }
        });

        req.on('error', (e) => console.error(`^1[DiscordScreen] Network Error: ${e.message}^7`));
        req.write(bodyBuffer);
        req.end();

    } catch (err) {
        console.error(`^1[DiscordScreen] Critical Error: ${err.message}^7`);
    }
});
