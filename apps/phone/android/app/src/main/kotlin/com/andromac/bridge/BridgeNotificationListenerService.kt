package com.andromac.bridge

import android.app.Notification
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.concurrent.ConcurrentHashMap

/**
 * Native NotificationListenerService intercepting incoming Android notifications,
 * extracting title/body/actions, and providing quick-reply dispatching via RemoteInput.
 */
class BridgeNotificationListenerService : NotificationListenerService() {

    companion object {
        var activeInstance: BridgeNotificationListenerService? = null
            private set

        // Cache of actions supporting RemoteInput mapped by notification key
        private val replyActionsCache = ConcurrentHashMap<String, Notification.Action>()

        /**
         * Dispatches quick reply text back into the originating messaging app.
         */
        fun replyToNotification(key: String, replyText: String): Boolean {
            val action = replyActionsCache[key] ?: return false
            val remoteInputs = action.remoteInputs ?: return false

            val intent = Intent()
            val bundle = Bundle()

            for (input in remoteInputs) {
                bundle.putCharSequence(input.resultKey, replyText)
            }
            RemoteInput.addResultsToIntent(remoteInputs, intent, bundle)

            return try {
                action.actionIntent.send(activeInstance, 0, intent)
                true
            } catch (e: PendingIntent.CanceledException) {
                false
            }
        }

        /**
         * Cancels/dismisses a notification on the phone by its unique key.
         */
        fun dismissNotification(key: String): Boolean {
            val service = activeInstance ?: return false
            service.cancelNotification(key)
            replyActionsCache.remove(key)
            return true
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        activeInstance = this
    }

    override fun onListenerDisconnected() {
        activeInstance = null
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        // Skip internal/system ongoing notifications or our own service notification
        if (sbn.packageName == packageName) return
        if (sbn.isOngoing && (sbn.notification.flags and Notification.FLAG_FOREGROUND_SERVICE) != 0) return

        val extras = sbn.notification.extras ?: Bundle()
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: ""

        // Skip empty notifications
        if (title.isBlank() && text.isBlank()) return

        var appName = sbn.packageName
        try {
            val appInfo = packageManager.getApplicationInfo(sbn.packageName, 0)
            appName = packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {}

        var canReply = false
        val actions = sbn.notification.actions
        if (actions != null) {
            for (action in actions) {
                if (action.remoteInputs != null && action.remoteInputs.isNotEmpty()) {
                    replyActionsCache[sbn.key] = action
                    canReply = true
                    break
                }
            }
        }

        val notifMap = hashMapOf<String, Any>(
            "key" to sbn.key,
            "packageName" to sbn.packageName,
            "appName" to appName,
            "title" to title,
            "text" to text,
            "postTime" to sbn.postTime,
            "canReply" to canReply
        )

        AndroidHostApiImpl.flutterApi?.onNotificationPosted(notifMap)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        replyActionsCache.remove(sbn.key)
        AndroidHostApiImpl.flutterApi?.onNotificationDismissed(sbn.key)
    }

    override fun onDestroy() {
        if (activeInstance == this) {
            activeInstance = null
        }
        replyActionsCache.clear()
        super.onDestroy()
    }
}
