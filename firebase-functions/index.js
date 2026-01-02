const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');

admin.initializeApp();

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || 'YOUR_BOT_TOKEN_HERE';

/**
 * Send message to Telegram
 */
async function sendTelegramMessage(chatId, text, parseMode = 'HTML') {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      chat_id: chatId,
      text: text,
      parse_mode: parseMode
    });

    const options = {
      hostname: 'api.telegram.org',
      path: `/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

/**
 * Cloud Function: Send Telegram alert when a notification is created
 * Trigger: users/{userId}/notifications/{notificationId} onCreate
 */
exports.sendTelegramAlert = functions
  .region('asia-southeast1')
  .firestore
  .document('users/{userId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const userId = context.params.userId;

    try {
      console.log(`📬 Processing notification for user: ${userId}`);
      console.log(`   Notification ID: ${context.params.notificationId}`);
      console.log(`   Type: ${notification.type}`);

      // Get user's Telegram chat ID
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.log(`   ⚠️ User document not found for: ${userId}`);
        return;
      }

      const userData = userDoc.data();
      const telegramChatId = userData?.telegramChatId;
      const telegramEnabled = userData?.telegramLinked === true;

      if (!telegramChatId) {
        console.log(`   ⚠️ No Telegram chat ID for user: ${userId}`);
        return;
      }

      if (!telegramEnabled) {
        console.log(`   ⚠️ Telegram disabled for user: ${userId}`);
        return;
      }

      // Format message based on notification type
      let message = '';
      let title = '';

      if (notification.type === 'report_status') {
        const reportId = notification.data?.reportId;
        const reportType = notification.data?.reportType;
        const newStatus = notification.data?.newStatus;
        const detailedInfo = notification.data?.detailedInfo || '';

        title = `🚨 Report Update`;
        message = `<b>${title}</b>\n\n`;
        message += `<b>Report ID:</b> <code>${reportId}</code>\n`;
        message += `<b>Type:</b> ${reportType}\n`;
        message += `<b>Status:</b> <code>${newStatus}</code>\n`;
        if (detailedInfo) {
          message += `\n<b>Details:</b> ${detailedInfo}`;
        }
        message += `\n\n<i>Tap the notification in the app to view full details</i>`;

      } else if (notification.type === 'aid_status') {
        const requestId = notification.data?.requestId;
        const aidType = notification.data?.aidType;
        const newStatus = notification.data?.newStatus;

        title = `🤝 Aid Request Update`;
        message = `<b>${title}</b>\n\n`;
        message += `<b>Request ID:</b> <code>${requestId}</code>\n`;
        message += `<b>Type:</b> ${aidType}\n`;
        message += `<b>Status:</b> <code>${newStatus}</code>\n`;
        message += `\n<i>Tap the notification in the app to view full details</i>`;

      } else if (notification.type === 'weather_alert') {
        const alertType = notification.data?.alertType;
        const location = notification.data?.location;
        const description = notification.data?.description;

        title = `⛈️ Weather Alert`;
        message = `<b>${title}</b>\n\n`;
        message += `<b>Type:</b> ${alertType}\n`;
        if (location) {
          message += `<b>Location:</b> ${location}\n`;
        }
        if (description) {
          message += `\n<b>Details:</b> ${description}`;
        }

      } else {
        // Generic notification
        title = notification.data?.title || 'Notification';
        message = `<b>${title}</b>\n\n`;
        message += notification.data?.description || notification.data?.message || 'New notification from RescueNet';
      }

      // Send the message
      console.log(`   📤 Sending Telegram message to chat: ${telegramChatId}`);
      const result = await sendTelegramMessage(telegramChatId, message);

      if (result.ok) {
        console.log(`   ✅ Telegram message sent successfully. Message ID: ${result.result?.message_id}`);
      } else {
        console.error(`   ❌ Telegram API error: ${result.description}`);
      }

    } catch (error) {
      console.error(`   ❌ Error sending Telegram alert: ${error.message}`);
      console.error(`   Stack: ${error.stack}`);
    }
  });

/**
 * HTTP Function: Telegram Webhook to handle incoming messages from bot
 * This allows the bot to receive updates from Telegram
 */
exports.telegramWebhook = functions
  .region('asia-southeast1')
  .https.onRequest(async (req, res) => {
    try {
      console.log('📨 Received Telegram webhook');
      console.log(`   Body: ${JSON.stringify(req.body)}`);

      const { message, callback_query } = req.body;

      if (message?.text === '/start') {
        // User started the bot
        const chatId = message.chat.id;
        const firstName = message.from.first_name;
        const username = message.from.username;

        console.log(`   User started bot: ${username} (${firstName})`);

        const responseText = `Welcome to <b>RescueNet</b>! 🚨\n\n` +
          `To receive emergency alerts via Telegram:\n\n` +
          `1️⃣ Open the <b>RescueNet app</b>\n` +
          `2️⃣ Go to <b>Notification Settings</b>\n` +
          `3️⃣ Tap <b>Connect Telegram</b>\n` +
          `4️⃣ Copy the verification code\n` +
          `5️⃣ Paste it here\n\n` +
          `You'll then receive instant alerts for emergency reports, aid requests, and more!`;

        await sendTelegramMessage(chatId, responseText);
        console.log(`   ✅ Welcome message sent`);

      } else if (message?.text) {
        // User sent a message - could be a verification code
        const chatId = message.chat.id;
        const text = message.text.trim();

        console.log(`   User message: ${text}`);

        // Check if it looks like a verification code (6 digits)
        if (/^\d{6}$/.test(text)) {
          const responseText = `✅ <b>Code received!</b>\n\n` +
            `Complete the linking process in the <b>RescueNet app</b> to activate Telegram alerts.`;
          await sendTelegramMessage(chatId, responseText);
          console.log(`   ✅ Verification code acknowledgment sent`);
        }

      } else if (callback_query) {
        // Handle button clicks if you add inline keyboards later
        console.log(`   Callback query: ${callback_query.data}`);
      }

      res.send({ ok: true });

    } catch (error) {
      console.error(`❌ Webhook error: ${error.message}`);
      res.status(500).send({ error: error.message });
    }
  });

/**
 * Test function to manually send a Telegram message (for debugging)
 * Trigger: POST /sendTestMessage?chatId=123&message=hello
 */
exports.sendTestMessage = functions
  .region('asia-southeast1')
  .https.onRequest(async (req, res) => {
    if (req.method !== 'POST') {
      return res.status(400).send('Method not allowed');
    }

    try {
      const { chatId, message } = req.query;

      if (!chatId || !message) {
        return res.status(400).send('Missing chatId or message');
      }

      const result = await sendTelegramMessage(chatId, message);

      if (result.ok) {
        res.send({ success: true, message: 'Message sent' });
      } else {
        res.status(400).send({ error: result.description });
      }

    } catch (error) {
      console.error('Test message error:', error);
      res.status(500).send({ error: error.message });
    }
  });

/**
 * Function to get list of available Cloud Functions (for debugging)
 */
exports.health = functions
  .region('asia-southeast1')
  .https.onRequest((req, res) => {
    res.json({
      status: 'healthy',
      functions: [
        'sendTelegramAlert - Triggered when notification created',
        'telegramWebhook - Receives messages from Telegram bot',
        'sendTestMessage - Manual test endpoint',
        'health - This endpoint'
      ]
    });
  });
