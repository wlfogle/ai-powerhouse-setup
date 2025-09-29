package com.garuda.mediastack

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.webkit.*
import android.widget.ProgressBar
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class WebViewActivity : AppCompatActivity() {
    
    private lateinit var webView: WebView
    private lateinit var progressBar: ProgressBar
    
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_webview)
        
        val serviceName = intent.getStringExtra("SERVICE_NAME") ?: "Service"
        val serviceUrl = intent.getStringExtra("SERVICE_URL") ?: ""
        
        title = serviceName
        
        webView = findViewById(R.id.webview)
        progressBar = findViewById(R.id.progress_bar)
        
        setupWebView()
        
        if (serviceUrl.isNotEmpty()) {
            webView.loadUrl(serviceUrl)
        } else {
            Toast.makeText(this, "Invalid service URL", Toast.LENGTH_SHORT).show()
            finish()
        }
    }
    
    private fun setupWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowContentAccess = true
            allowFileAccess = true
            setSupportZoom(true)
            builtInZoomControls = true
            displayZoomControls = false
            useWideViewPort = true
            loadWithOverviewMode = true
            
            // Enable hardware acceleration
            setRenderPriority(WebSettings.RenderPriority.HIGH)
            cacheMode = WebSettings.LOAD_DEFAULT
            
            // User agent for better compatibility
            userAgentString = "Mozilla/5.0 (Linux; Android 10; TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36"
        }
        
        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                super.onPageStarted(view, url, favicon)
                progressBar.visibility = View.VISIBLE
            }
            
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                progressBar.visibility = View.GONE
            }
            
            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: WebResourceError?
            ) {
                super.onReceivedError(view, request, error)
                progressBar.visibility = View.GONE
                Toast.makeText(this@WebViewActivity, 
                    "Connection error: ${error?.description}", 
                    Toast.LENGTH_LONG).show()
            }
        }
        
        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                progressBar.progress = newProgress
            }
        }
    }
    
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && webView.canGoBack()) {
            webView.goBack()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
    
    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }
}
