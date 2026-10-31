package com.bstream.bstream_music

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.util.Log
import com.ryanheise.audioservice.AudioService

/**
 * Sends widget queue selections and the repeat/favorite buttons to the same
 * media session as notification controls, so they work without opening the app.
 */
class BStreamWidgetPlaybackReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.getStringExtra(MainActivity.EXTRA_HOME_WIDGET_ACTION) ?: return
        when (intent.action) {
            ACTION_PLAY_QUEUE_ITEM -> {
                if (!action.startsWith(MainActivity.HOME_WIDGET_QUEUE_PREFIX)) return
                val index = action.removePrefix(MainActivity.HOME_WIDGET_QUEUE_PREFIX)
                    .toIntOrNull()?.takeIf { it >= 0 } ?: return
                PlaybackRequest(context.applicationContext, index, null, goAsync()).connect()
            }
            ACTION_WIDGET_CONTROL -> {
                if (action !in WIDGET_CONTROLS) return
                PlaybackRequest(context.applicationContext, null, action, goAsync()).connect()
            }
        }
    }

    private class PlaybackRequest(
        private val context: Context,
        private val index: Int?,
        private val control: String?,
        private val pending: PendingResult,
    ) : MediaBrowserCompat.ConnectionCallback() {
        private val handler = Handler(Looper.getMainLooper())
        private var finished = false
        private var controller: MediaControllerCompat? = null
        private val browser = MediaBrowserCompat(
            context, ComponentName(context, AudioService::class.java), this, null,
        )
        private val timeout = Runnable { finish() }
        private val callback = object : MediaControllerCompat.Callback() {
            override fun onQueueChanged(queue: MutableList<MediaSessionCompat.QueueItem>?) {
                playWhenReady()
            }

            override fun onMetadataChanged(metadata: MediaMetadataCompat?) {
                playWhenReady()
            }

            override fun onSessionDestroyed() = finish()
        }

        fun connect() {
            // A cold media service can connect before Dart has restored its
            // queue. Wait for that publication, without starting an Activity.
            handler.postDelayed(timeout, 8_000)
            try {
                browser.connect()
            } catch (error: Exception) {
                Log.w(TAG, "Unable to connect widget to playback", error)
                finish()
            }
        }

        override fun onConnected() {
            try {
                controller = MediaControllerCompat(context, browser.sessionToken).also {
                    it.registerCallback(callback, handler)
                }
                playWhenReady()
            } catch (error: Exception) {
                Log.w(TAG, "Unable to select widget queue item", error)
                finish()
            }
        }

        private fun playWhenReady() {
            if (finished) return
            val media = controller ?: return
            if (control != null) {
                // Favorite needs the current song, so wait until Dart has
                // published it.
                media.metadata ?: return
                media.transportControls.sendCustomAction(
                    CUSTOM_ACTION_WIDGET,
                    Bundle().apply { putString("action", control) },
                )
                finish()
                return
            }
            val queue = media.queue?.takeIf { it.isNotEmpty() } ?: return
            if (index != null && index < queue.size) {
                media.transportControls.skipToQueueItem(queue[index].queueId)
            }
            finish()
        }

        override fun onConnectionFailed() = finish()

        override fun onConnectionSuspended() = finish()

        private fun finish() {
            if (finished) return
            finished = true
            handler.removeCallbacks(timeout)
            controller?.unregisterCallback(callback)
            browser.disconnect()
            pending.finish()
        }
    }

    companion object {
        private const val TAG = "BStreamWidgetPlayback"
        private const val ACTION_PLAY_QUEUE_ITEM = "com.bstream.bstream_music.WIDGET_QUEUE_PLAY"
        private const val ACTION_WIDGET_CONTROL = "com.bstream.bstream_music.WIDGET_CONTROL"

        /** Must match `homeWidgetMediaAction` in audio_service_desktop_media_session.dart. */
        private const val CUSTOM_ACTION_WIDGET = "bstream_music.widget_action"
        private val WIDGET_CONTROLS = setOf("repeat", "favorite")

        fun controlIntent(context: Context, control: String): PendingIntent {
            val intent = Intent(context, BStreamWidgetPlaybackReceiver::class.java).apply {
                action = ACTION_WIDGET_CONTROL
                data = Uri.parse("bstream-widget://control/$control")
                putExtra(MainActivity.EXTRA_HOME_WIDGET_ACTION, control)
            }
            return PendingIntent.getBroadcast(
                context, 9000 + control.hashCode(), intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun queueClickTemplate(context: Context, appWidgetId: Int): PendingIntent {
            val intent = Intent(context, BStreamWidgetPlaybackReceiver::class.java).apply {
                action = ACTION_PLAY_QUEUE_ITEM
                data = Uri.parse("bstream-widget://queue/$appWidgetId/play")
            }
            val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else 0
            return PendingIntent.getBroadcast(
                context, 9100 + appWidgetId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag,
            )
        }
    }
}
