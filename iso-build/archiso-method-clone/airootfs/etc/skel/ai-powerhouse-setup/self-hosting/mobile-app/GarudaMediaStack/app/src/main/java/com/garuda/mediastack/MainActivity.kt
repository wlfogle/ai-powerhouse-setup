package com.garuda.mediastack

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.card.MaterialCardView

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        setupServiceCards()
    }

    private fun setupServiceCards() {
        // Content Management - Working Services
        findViewById<MaterialCardView>(R.id.card_radarr).setOnClickListener {
            openService("Radarr", getString(R.string.radarr_url))
        }
        
        findViewById<MaterialCardView>(R.id.card_sonarr).setOnClickListener {
            openService("Sonarr", getString(R.string.sonarr_url))
        }
        
        findViewById<MaterialCardView>(R.id.card_lidarr).setOnClickListener {
            openService("Lidarr", getString(R.string.lidarr_url))
        }

        // Downloads & Search - Working Services
        findViewById<MaterialCardView>(R.id.card_qbittorrent).setOnClickListener {
            openService("qBittorrent", getString(R.string.qbittorrent_url))
        }
        
        findViewById<MaterialCardView>(R.id.card_jackett).setOnClickListener {
            openService("Jackett", getString(R.string.jackett_url))
        }
    }

    private fun openService(serviceName: String, url: String) {
        val intent = Intent(this, WebViewActivity::class.java).apply {
            putExtra("SERVICE_NAME", serviceName)
            putExtra("SERVICE_URL", url)
        }
        startActivity(intent)
    }
}
