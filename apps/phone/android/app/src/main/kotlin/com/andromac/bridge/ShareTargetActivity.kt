package com.andromac.bridge

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

/**
 * Transparent activity handling Android Share Sheet actions (`ACTION_SEND` / `ACTION_SEND_MULTIPLE`)
 * to instantly transfer text, URLs, or files directly to the paired Mac.
 */
class ShareTargetActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        handleShareIntent(intent)
        finish()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { handleShareIntent(it) }
        finish()
    }

    private fun handleShareIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            if ("text/plain" == type) {
                val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (!sharedText.isNullOrEmpty()) {
                    AndroidHostApiImpl.flutterApi?.onClipboardCaptured(sharedText)
                    Toast.makeText(this, "Shared to Mac", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}
