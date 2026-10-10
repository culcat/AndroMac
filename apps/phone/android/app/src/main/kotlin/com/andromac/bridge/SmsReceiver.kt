package com.andromac.bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * BroadcastReceiver listening for incoming SMS messages.
 * Reassembles multi-part PDUs and dispatches them to Flutter without logging sensitive text.
 */
class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        val firstMessage = messages[0]
        val address = firstMessage.displayOriginatingAddress ?: "Unknown"
        val timestamp = firstMessage.timestampMillis

        // Concatenate multi-part SMS body segments
        val bodyBuilder = StringBuilder()
        for (message in messages) {
            val bodySegment = message.displayMessageBody
            if (bodySegment != null) {
                bodyBuilder.append(bodySegment)
            }
        }

        val fullBody = bodyBuilder.toString()
        val messageId = "sms-$timestamp-${address.hashCode()}"

        val smsMap = hashMapOf<String, Any>(
            "messageId" to messageId,
            "threadId" to address,
            "address" to address,
            "body" to fullBody,
            "timestamp" to timestamp
        )

        AndroidHostApiImpl.flutterApi?.onSmsReceived(smsMap)
    }
}
