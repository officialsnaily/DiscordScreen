/**
 * DiscordScreen - Server JS Helper (With Queue & Rate Limit Protection)
 * Author: Snaily Labs
 */

const https = require('https');
const url = require('url');

console.log('^3[DiscordScreen] JS Uploader (Snaily Labs Edition) loaded with Rate-Limit Queue.^7');

// --- QUEUE SYSTEM VARIABLES ---
const uploadQueue = [];
let isProcessing = false;

// Event: Add upload task to queue
on('DiscordScreen:executeJS_Upload', (webhookUrl, base64Data, embedJson) => {
    // Basic validation to prevent crashes with default config
    if (!webhookUrl || webhookUrl.includes("YOUR_WEBHOOK")) return;

    uploadQueue.push({ webhookUrl, base64Data, embedJson });
    
    // If the processor is idle, start it up
    if (!isProcessing) {
        processQueue();
    }
});

/**
 * Processes the next item in the upload queue.
 * Handles waiting times and retries.
 */
function processQueue() {
    if (uploadQueue.length === 0) {
        isProcessing = false;
        return;
    }

    isProcessing = true;
    const currentTask = uploadQueue[0]; // Peek at the first item (don't remove yet)

    uploadToDiscord(currentTask, (success, retryAfter) => {
        if (success) {
            // Success! Remove task from queue
            uploadQueue.shift(); 
            // Wait 2 seconds before next upload to be safe
            setTimeout(processQueue, 2000); 
        } else {
            // Failed due to Rate Limit (429)
            if (retryAfter) {
                const waitTime = (retryAfter * 1000) + 500; // Discord time + 0.5s buffer
                console.log(`^3[DiscordScreen] Rate Limit Hit! Pausing queue for ${waitTime}ms...^7`);
                setTimeout(processQueue, waitTime);
            } else {
                // Unknown error? Remove to prevent clogging the queue
                console.log(`^1[DiscordScreen] Upload failed with unknown error. Skipping.^7`);
                uploadQueue.shift();
                setTimeout(processQueue, 2000);
            }
        }
    });
}

/**
 * Performs the actual HTTPS request to Discord.
 */
function uploadToDiscord(task, callback) {
    try {
        const { webhookUrl, base64Data, embedJson } = task;
        
        // Clean base64 string
        const base64Image = base64Data.replace(/^data:image\/[a-z]+;base64,/, "");
        const imageBuffer = Buffer.from(base64Image, 'base64');
        const boundary = '----SnailyLabsBoundary' + Date.now();
        
        // Construct Multipart Payload
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
            
            if (res.statusCode === 200 || res.statusCode === 204) {
                // SUCCESS
                callback(true);
            } else if (res.statusCode === 429) {
                // RATE LIMITED
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        // Call callback with FALSE (failed) and the wait time
                        callback(false, response.retry_after); 
                    } catch (e) {
                        callback(false, 5); // Default 5 sec wait if parsing fails
                    }
                });
            } else {
                // OTHER ERROR
                console.log(`^1[DiscordScreen] Error: Discord returned status ${res.statusCode}^7`);
                callback(false, null);
            }
        });

        req.on('error', (e) => {
            console.error(`^1[DiscordScreen] Network Error: ${e.message}^7`);
            callback(false, null);
        });
        
        req.write(bodyBuffer);
        req.end();

    } catch (err) {
        console.error(`^1[DiscordScreen] Critical Error: ${err.message}^7`);
        callback(false, null);
    }
}
