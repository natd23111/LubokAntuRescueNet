const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');

admin.initializeApp();

// Bot token - update this with your actual token
const TELEGRAM_BOT_TOKEN = '';

/**
 * Send message to Telegram (works with both individual and group chats)
 * @param {number|string} chatId - User chat ID (positive) or Group chat ID (negative)
 * @param {string} text - Message text
 * @param {string} parseMode - Parse mode (HTML or Markdown)
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
 * Get group/chat information
 */
async function getTelegramChatInfo(chatId) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.telegram.org',
      path: `/bot${TELEGRAM_BOT_TOKEN}/getChat?chat_id=${chatId}`,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
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
        const oldStatus = notification.data?.oldStatus;
        const detailedInfo = notification.data?.detailedInfo || '';
        const location = notification.data?.location || 'Not specified';
        const description = notification.data?.description || '';
        const createdBy = notification.data?.createdBy || 'Unknown';
        const createdAt = notification.data?.createdAt || '';
        const priority = notification.data?.priority || 'Normal';
        const category = notification.data?.category || '';
        const affectedArea = notification.data?.affectedArea || '';
        const estimatedDamage = notification.data?.estimatedDamage || '';
        const victimCount = notification.data?.victimCount || '';

        title = `🚨 Report Status Update`;
        message = `<b>${title}</b>\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━\n\n`;
        message += `<b>📋 Report ID:</b> <code>${reportId}</code>\n`;
        message += `<b>🏷️ Type:</b> <code>${reportType}</code>\n`;
        if (category) message += `<b>📂 Category:</b> ${category}\n`;
        message += `<b>📍 Location:</b> ${location}\n`;
        if (affectedArea) message += `<b>🗺️ Affected Area:</b> ${affectedArea}\n`;
        message += `<b>⚡ Priority:</b> ${priority}\n\n`;
        
        message += `<b>Status Change:</b>\n`;
        message += `  ${oldStatus} ➜ <code>${newStatus}</code>\n\n`;
        
        message += `<b>👤 Reported By:</b> ${createdBy}\n`;
        if (createdAt) message += `<b>⏰ Time:</b> ${createdAt}\n`;
        
        if (victimCount) message += `<b>👥 Victims:</b> ${victimCount} people\n`;
        if (estimatedDamage) message += `<b>💔 Damage:</b> ${estimatedDamage}\n`;
        
        if (description) {
          message += `\n<b>📝 Description:</b>\n${description}\n`;
        }
        if (detailedInfo) {
          message += `\n<b>ℹ️ Additional Details:</b>\n${detailedInfo}\n`;
        }
        message += `\n━━━━━━━━━━━━━━━━━━━━━\n`;
        message += `<i>Open the app to view full details and take action</i>`;

      } else if (notification.type === 'aid_status') {
        const requestId = notification.data?.requestId;
        const aidType = notification.data?.aidType;
        const newStatus = notification.data?.newStatus;
        const oldStatus = notification.data?.oldStatus;
        const description = notification.data?.description || '';
        const amount = notification.data?.amount || '';
        const location = notification.data?.location || '';
        const requestedBy = notification.data?.requestedBy || 'Unknown';
        const createdAt = notification.data?.createdAt || '';
        const priority = notification.data?.priority || 'Normal';
        const beneficiaries = notification.data?.beneficiaries || '';
        const contactInfo = notification.data?.contactInfo || '';

        title = `🤝 Aid Request Update`;
        message = `<b>${title}</b>\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━\n\n`;
        message += `<b>📋 Request ID:</b> <code>${requestId}</code>\n`;
        message += `<b>🏷️ Type:</b> <code>${aidType}</code>\n`;
        if (amount) {
          message += `<b>💰 Amount:</b> ${amount}\n`;
        }
        if (location) {
          message += `<b>📍 Location:</b> ${location}\n`;
        }
        message += `<b>⚡ Priority:</b> ${priority}\n\n`;
        
        message += `<b>Status:</b> ${oldStatus} ➜ <code>${newStatus}</code>\n\n`;
        
        message += `<b>👤 Requested By:</b> ${requestedBy}\n`;
        if (createdAt) message += `<b>⏰ Time:</b> ${createdAt}\n`;
        if (beneficiaries) message += `<b>👥 Beneficiaries:</b> ${beneficiaries}\n`;
        if (contactInfo) message += `<b>📞 Contact:</b> ${contactInfo}\n`;
        
        if (description) {
          message += `\n<b>📝 Details:</b>\n${description}\n`;
        }
        message += `\n━━━━━━━━━━━━━━━━━━━━━\n`;
        message += `<i>Open the app for full information and updates</i>`;

      } else if (notification.type === 'weather_alert') {
        const alertType = notification.data?.alertType || 'Weather Alert';
        const location = notification.data?.location || 'Your area';
        const description = notification.data?.description || '';
        const temperature = notification.data?.temperature;
        const windSpeed = notification.data?.windSpeed;
        const humidity = notification.data?.humidity;
        const rainfall = notification.data?.rainfall;
        const severity = notification.data?.severity || 'Unknown';
        const startTime = notification.data?.startTime || '';
        const endTime = notification.data?.endTime || '';
        const affectedAreas = notification.data?.affectedAreas || '';
        const recommendations = notification.data?.recommendations || '';

        title = `⚠️ Weather Alert`;
        message = `<b>${title}</b>\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━\n\n`;
        message += `<b>🚨 Alert Type:</b> <code>${alertType}</code>\n`;
        message += `<b>📍 Location:</b> ${location}\n`;
        if (affectedAreas) message += `<b>🗺️ Affected Areas:</b> ${affectedAreas}\n`;
        message += `<b>🔴 Severity:</b> ${severity}\n\n`;
        
        message += `<b>Weather Data:</b>\n`;
        if (temperature) message += `  🌡️ Temperature: ${temperature}°C\n`;
        if (humidity) message += `  💧 Humidity: ${humidity}%\n`;
        if (windSpeed) message += `  💨 Wind Speed: ${windSpeed} km/h\n`;
        if (rainfall) message += `  🌧️ Rainfall: ${rainfall} mm\n`;
        
        if (startTime || endTime) {
          message += `\n<b>⏰ Duration:</b>\n`;
          if (startTime) message += `  Start: ${startTime}\n`;
          if (endTime) message += `  End: ${endTime}\n`;
        }
        
        if (description) {
          message += `\n<b>📝 Alert Details:</b>\n${description}\n`;
        }
        
        if (recommendations) {
          message += `\n<b>✅ Recommendations:</b>\n${recommendations}\n`;
        }
        
        message += `\n━━━━━━━━━━━━━━━━━━━━━\n`;
        message += `<i>Take necessary precautions and stay safe</i>`;

      } else {
        // Generic notification - extract all available fields
        title = notification.data?.title || 'RescueNet Alert';
        const description = notification.data?.description || 'New notification';
        const timestamp = notification.data?.timestamp || new Date().toISOString();
        const category = notification.data?.category || '';
        const source = notification.data?.source || '';
        const priority = notification.data?.priority || '';
        const location = notification.data?.location || '';
        const status = notification.data?.status || '';
        const actionUrl = notification.data?.actionUrl || '';
        
        message = `<b>${title}</b>\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━\n\n`;
        
        if (category) message += `<b>📂 Category:</b> ${category}\n`;
        if (source) message += `<b>📡 Source:</b> ${source}\n`;
        if (priority) message += `<b>⚡ Priority:</b> ${priority}\n`;
        if (location) message += `<b>📍 Location:</b> ${location}\n`;
        if (status) message += `<b>📊 Status:</b> ${status}\n`;
        
        message += `\n<b>📝 Description:</b>\n${description}\n\n`;
        message += `<b>⏰ Time:</b> ${new Date(timestamp).toLocaleString()}\n`;
        
        message += `━━━━━━━━━━━━━━━━━━━━━\n`;
        message += `<i>Open the app for complete details and actions</i>`;
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

      } else if (message?.text === '/chatid') {
        // Admin command to get group chat ID
        const chatId = message.chat.id;
        const chatTitle = message.chat.title || message.chat.username || 'Direct Message';
        const chatType = message.chat.type; // 'group', 'supergroup', 'private'
        
        console.log(`   /chatid command - Chat: ${chatTitle} (${chatType})`);

        let responseText = `<b>Chat Information:</b>\n\n`;
        responseText += `<b>Chat ID:</b> <code>${chatId}</code>\n`;
        responseText += `<b>Chat Name:</b> ${chatTitle}\n`;
        responseText += `<b>Type:</b> ${chatType}\n\n`;
        
        if (chatType === 'group' || chatType === 'supergroup') {
          responseText += `✅ <b>This is a group chat!</b>\n`;
          responseText += `You can use this Chat ID to send notifications to this entire group.\n\n`;
          responseText += `<i>Share the Chat ID with your RescueNet admin to enable group notifications.</i>`;
        } else {
          responseText += `This is a direct message chat.\n`;
          responseText += `For group alerts, add this bot to a group and use /chatid there.`;
        }

        await sendTelegramMessage(chatId, responseText);
        console.log(`   ✅ Chat ID information sent`);

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
