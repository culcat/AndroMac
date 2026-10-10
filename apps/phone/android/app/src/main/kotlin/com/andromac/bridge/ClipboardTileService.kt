package com.andromac.bridge

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.widget.Toast
import androidx.annotation.RequiresApi

/**
 * Quick Settings Tile enabling 1-tap clipboard synchronization from Android to Mac.
 * Resolves the Android 10+ limitation prohibiting background clipboard reads.
 */
@RequiresApi(Build.VERSION_CODES.N)
class ClipboardTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile ?: return
        tile.state = Tile.STATE_ACTIVE
        tile.label = "Sync to Mac"
        tile.updateTile()
    }

    override fun onClick() {
        super.onClick()

        val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        if (!clipboardManager.hasPrimaryClip()) {
            Toast.makeText(this, "Clipboard is empty", Toast.LENGTH_SHORT).show()
            return
        }

        val clip = clipboardManager.primaryClip
        if (clip != null && clip.itemCount > 0) {
            val text = clip.getItemAt(0).coerceToText(this)?.toString()
            if (!text.isNullOrEmpty()) {
                AndroidHostApiImpl.flutterApi?.onClipboardCaptured(text)
                Toast.makeText(this, "Copied to Mac", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
