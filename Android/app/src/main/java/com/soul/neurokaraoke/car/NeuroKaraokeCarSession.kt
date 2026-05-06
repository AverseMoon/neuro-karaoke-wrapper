package com.soul.neurokaraoke.car

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

class NeuroKaraokeCarSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen = HomeCarScreen(carContext)
}
