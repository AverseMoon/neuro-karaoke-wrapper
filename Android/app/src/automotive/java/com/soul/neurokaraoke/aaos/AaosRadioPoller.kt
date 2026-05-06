package com.soul.neurokaraoke.aaos

import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.session.MediaController
import com.soul.neurokaraoke.data.api.RadioApi
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Polls RadioApi every 15s and pushes fresh title/artist/cover into the
 * MediaController's current item metadata so the now-playing UI updates
 * as live songs change.
 */
object AaosRadioPoller {
    private val api = RadioApi()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var job: Job? = null

    fun start(controller: MediaController) {
        stop()
        job = scope.launch {
            // Push immediately, then every 15s
            while (isActive) {
                api.fetchCurrentState().onSuccess { state ->
                    val current = state.current ?: return@onSuccess
                    val newMeta = MediaMetadata.Builder()
                        .setTitle(current.title)
                        .setArtist(current.originalArtists.joinToString(", "))
                        .setAlbumTitle("Neuro 21 Station • LIVE")
                        .setMediaType(MediaMetadata.MEDIA_TYPE_MUSIC)
                        .setIsPlayable(true)
                        .apply {
                            if (current.coverUrl.isNotBlank()) {
                                setArtworkUri(Uri.parse(current.coverUrl))
                            }
                        }
                        .build()

                    withContext(Dispatchers.Main) {
                        if (controller.mediaItemCount > 0 &&
                            controller.currentMediaItem?.mediaId == "radio_live"
                        ) {
                            val updated = controller.currentMediaItem
                                ?.buildUpon()
                                ?.setMediaMetadata(newMeta)
                                ?.build()
                            if (updated != null) {
                                try {
                                    controller.replaceMediaItem(controller.currentMediaItemIndex, updated)
                                } catch (_: Exception) {
                                    // older Media3 — ignore
                                }
                            }
                        } else {
                            // Stream switched away from radio — stop polling
                            stop()
                        }
                    }
                }
                delay(15_000L)
            }
        }
    }

    fun stop() {
        job?.cancel()
        job = null
    }
}
