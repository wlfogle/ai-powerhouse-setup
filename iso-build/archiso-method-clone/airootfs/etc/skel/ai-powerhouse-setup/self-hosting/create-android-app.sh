#!/bin/bash

# CREATE GARUDA MEDIA STACK ANDROID/FIRETV APP
# Complete Android Studio project with unified media access

echo "📱 CREATING GARUDA MEDIA STACK ANDROID/FIRETV APP..."

# Create Android project directory structure
mkdir -p mobile-app/GarudaMediaStack/{app/src/main/{java/com/garuda/mediastack,res/{layout,values,drawable,mipmap-{hdpi,mdpi,xhdpi,xxhdpi,xxxhdpi}}}}

cd mobile-app/GarudaMediaStack

echo "🔧 Creating Android project files..."

# Create build.gradle (Project level)
cat > build.gradle << 'EOF'
buildscript {
    ext.kotlin_version = "1.9.10"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.2"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# Create app/build.gradle
cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.garuda.mediastack'
    compileSdk 34

    defaultConfig {
        applicationId "com.garuda.mediastack"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = '1.8'
    }

    buildFeatures {
        viewBinding true
    }

    // Support for Android TV/Fire TV
    leanback {
        enabled true
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.10.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'androidx.cardview:cardview:1.0.0'
    
    // Android TV/Leanback support
    implementation 'androidx.leanback:leanback:1.0.0'
    implementation 'androidx.leanback:leanback-preference:1.0.0'
    
    // Networking
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    
    // Image loading
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    
    // WebView
    implementation 'androidx.webkit:webkit:1.8.0'
    
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
EOF

# Create AndroidManifest.xml
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    
    <!-- TV/Fire TV Features -->
    <uses-feature
        android:name="android.software.leanback"
        android:required="false" />
    <uses-feature
        android:name="android.hardware.touchscreen"
        android:required="false" />

    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.GarudaMediaStack"
        android:usesCleartextTraffic="true"
        tools:targetApi="31">

        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="landscape"
            android:theme="@style/Theme.GarudaMediaStack">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Web View Activity for Services -->
        <activity
            android:name=".WebViewActivity"
            android:exported="false"
            android:screenOrientation="landscape" />

    </application>

</manifest>
EOF

echo "🎨 Creating app layouts and resources..."

# Create main activity layout
cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/background_dark"
    android:padding="16dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <!-- Header -->
        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:gravity="center_vertical"
            android:layout_marginBottom="24dp">

            <ImageView
                android:layout_width="48dp"
                android:layout_height="48dp"
                android:src="@mipmap/ic_launcher"
                android:layout_marginEnd="16dp" />

            <TextView
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:text="Garuda Media Stack"
                android:textSize="24sp"
                android:textColor="@color/text_primary"
                android:textStyle="bold" />

        </LinearLayout>

        <!-- Media Servers Section -->
        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="🎬 Media Servers"
            android:textSize="18sp"
            android:textColor="@color/text_primary"
            android:textStyle="bold"
            android:layout_marginBottom="16dp" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:layout_marginBottom="24dp">

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_jellyfin"
                style="@style/ServiceCard">
                <LinearLayout style="@style/ServiceCardContent">
                    <ImageView
                        android:layout_width="32dp"
                        android:layout_height="32dp"
                        android:src="@drawable/ic_jellyfin"
                        android:layout_marginBottom="8dp" />
                    <TextView
                        style="@style/ServiceTitle"
                        android:text="Jellyfin" />
                    <TextView
                        style="@style/ServiceSubtitle"
                        android:text="Media Server" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_calibre"
                style="@style/ServiceCard">
                <LinearLayout style="@style/ServiceCardContent">
                    <ImageView
                        android:layout_width="32dp"
                        android:layout_height="32dp"
                        android:src="@drawable/ic_book"
                        android:layout_marginBottom="8dp" />
                    <TextView
                        style="@style/ServiceTitle"
                        android:text="Lou's Library" />
                    <TextView
                        style="@style/ServiceSubtitle"
                        android:text="Books & eBooks" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

        </LinearLayout>

        <!-- Content Management Section -->
        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="📋 Content Management"
            android:textSize="18sp"
            android:textColor="@color/text_primary"
            android:textStyle="bold"
            android:layout_marginBottom="16dp" />

        <GridLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:columnCount="2"
            android:rowCount="2"
            android:layout_marginBottom="24dp">

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_radarr"
                style="@style/ServiceCardSmall">
                <LinearLayout style="@style/ServiceCardContentSmall">
                    <TextView style="@style/ServiceTitleSmall" android:text="🎬 Radarr" />
                    <TextView style="@style/ServiceSubtitleSmall" android:text="Movies" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_sonarr"
                style="@style/ServiceCardSmall">
                <LinearLayout style="@style/ServiceCardContentSmall">
                    <TextView style="@style/ServiceTitleSmall" android:text="📺 Sonarr" />
                    <TextView style="@style/ServiceSubtitleSmall" android:text="TV Shows" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_lidarr"
                style="@style/ServiceCardSmall">
                <LinearLayout style="@style/ServiceCardContentSmall">
                    <TextView style="@style/ServiceTitleSmall" android:text="🎵 Lidarr" />
                    <TextView style="@style/ServiceSubtitleSmall" android:text="Music" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_readarr"
                style="@style/ServiceCardSmall">
                <LinearLayout style="@style/ServiceCardContentSmall">
                    <TextView style="@style/ServiceTitleSmall" android:text="📚 Readarr" />
                    <TextView style="@style/ServiceSubtitleSmall" android:text="Books" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

        </GridLayout>

        <!-- Downloads Section -->
        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="⬇️ Downloads & Search"
            android:textSize="18sp"
            android:textColor="@color/text_primary"
            android:textStyle="bold"
            android:layout_marginBottom="16dp" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal">

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_qbittorrent"
                style="@style/ServiceCard">
                <LinearLayout style="@style/ServiceCardContent">
                    <ImageView
                        android:layout_width="32dp"
                        android:layout_height="32dp"
                        android:src="@drawable/ic_download"
                        android:layout_marginBottom="8dp" />
                    <TextView
                        style="@style/ServiceTitle"
                        android:text="qBittorrent" />
                    <TextView
                        style="@style/ServiceSubtitle"
                        android:text="Downloads" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

            <com.google.android.material.card.MaterialCardView
                android:id="@+id/card_jackett"
                style="@style/ServiceCard">
                <LinearLayout style="@style/ServiceCardContent">
                    <ImageView
                        android:layout_width="32dp"
                        android:layout_height="32dp"
                        android:src="@drawable/ic_search"
                        android:layout_marginBottom="8dp" />
                    <TextView
                        style="@style/ServiceTitle"
                        android:text="Jackett" />
                    <TextView
                        style="@style/ServiceSubtitle"
                        android:text="Search" />
                </LinearLayout>
            </com.google.android.material.card.MaterialCardView>

        </LinearLayout>

    </LinearLayout>

</ScrollView>
EOF

echo "🎨 Creating styles and colors..."

# Create styles.xml
cat > app/src/main/res/values/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>

    <style name="ServiceCard">
        <item name="android:layout_width">0dp</item>
        <item name="android:layout_height">120dp</item>
        <item name="android:layout_weight">1</item>
        <item name="android:layout_margin">8dp</item>
        <item name="android:clickable">true</item>
        <item name="android:focusable">true</item>
        <item name="cardBackgroundColor">@color/card_background</item>
        <item name="cardCornerRadius">12dp</item>
        <item name="cardElevation">4dp</item>
    </style>

    <style name="ServiceCardSmall">
        <item name="android:layout_width">0dp</item>
        <item name="android:layout_height">80dp</item>
        <item name="android:layout_columnWeight">1</item>
        <item name="android:layout_margin">4dp</item>
        <item name="android:clickable">true</item>
        <item name="android:focusable">true</item>
        <item name="cardBackgroundColor">@color/card_background</item>
        <item name="cardCornerRadius">8dp</item>
        <item name="cardElevation">2dp</item>
    </style>

    <style name="ServiceCardContent">
        <item name="android:layout_width">match_parent</item>
        <item name="android:layout_height">match_parent</item>
        <item name="android:orientation">vertical</item>
        <item name="android:gravity">center</item>
        <item name="android:padding">16dp</item>
    </style>

    <style name="ServiceCardContentSmall">
        <item name="android:layout_width">match_parent</item>
        <item name="android:layout_height">match_parent</item>
        <item name="android:orientation">vertical</item>
        <item name="android:gravity">center</item>
        <item name="android:padding">8dp</item>
    </style>

    <style name="ServiceTitle">
        <item name="android:layout_width">wrap_content</item>
        <item name="android:layout_height">wrap_content</item>
        <item name="android:textSize">16sp</item>
        <item name="android:textColor">@color/text_primary</item>
        <item name="android:textStyle">bold</item>
    </style>

    <style name="ServiceTitleSmall">
        <item name="android:layout_width">wrap_content</item>
        <item name="android:layout_height">wrap_content</item>
        <item name="android:textSize">14sp</item>
        <item name="android:textColor">@color/text_primary</item>
        <item name="android:textStyle">bold</item>
    </style>

    <style name="ServiceSubtitle">
        <item name="android:layout_width">wrap_content</item>
        <item name="android:layout_height">wrap_content</item>
        <item name="android:textSize">12sp</item>
        <item name="android:textColor">@color/text_secondary</item>
        <item name="android:layout_marginTop">4dp</item>
    </style>

    <style name="ServiceSubtitleSmall">
        <item name="android:layout_width">wrap_content</item>
        <item name="android:layout_height">wrap_content</item>
        <item name="android:textSize">10sp</item>
        <item name="android:textColor">@color/text_secondary</item>
        <item name="android:layout_marginTop">2dp</item>
    </style>

</resources>
EOF

# Create colors.xml
cat > app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
    
    <!-- Garuda Theme Colors -->
    <color name="background_dark">#FF1A1A1A</color>
    <color name="card_background">#FF2D2D2D</color>
    <color name="text_primary">#FFFFFFFF</color>
    <color name="text_secondary">#FFCCCCCC</color>
    <color name="accent">#FF4CAF50</color>
    
    <!-- Service Colors -->
    <color name="jellyfin_primary">#FF00A4DC</color>
    <color name="radarr_primary">#FFFFC230</color>
    <color name="sonarr_primary">#FF35C5F0</color>
    <color name="lidarr_primary">#FFE25B3C</color>
    <color name="jackett_primary">#FF9117FF</color>
</resources>
EOF

# Create strings.xml
cat > app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Garuda Media Stack</string>
    <string name="server_ip">192.168.12.172</string>
    
    <!-- Service URLs -->
    <string name="jellyfin_url">http://192.168.12.172:8096</string>
    <string name="calibre_url">http://192.168.12.172:8083</string>
    <string name="radarr_url">http://192.168.12.172:7878</string>
    <string name="sonarr_url">http://192.168.12.172:8989</string>
    <string name="lidarr_url">http://192.168.12.172:8686</string>
    <string name="readarr_url">http://192.168.12.172:8787</string>
    <string name="qbittorrent_url">http://192.168.12.172:5080</string>
    <string name="jackett_url">http://192.168.12.172:9117</string>
    
    <!-- Messages -->
    <string name="loading">Loading...</string>
    <string name="connection_error">Connection Error</string>
    <string name="check_network">Please check your network connection</string>
</resources>
EOF

echo "📱 Creating MainActivity..."

# Create MainActivity.kt
cat > app/src/main/java/com/garuda/mediastack/MainActivity.kt << 'EOF'
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
        // Media Servers
        findViewById<MaterialCardView>(R.id.card_jellyfin).setOnClickListener {
            openService("Jellyfin", getString(R.string.jellyfin_url))
        }
        
        findViewById<MaterialCardView>(R.id.card_calibre).setOnClickListener {
            openService("Lou's Library", getString(R.string.calibre_url))
        }

        // Content Management
        findViewById<MaterialCardView>(R.id.card_radarr).setOnClickListener {
            openService("Radarr", getString(R.string.radarr_url))
        }
        
        findViewById<MaterialCardView>(R.id.card_sonarr).setOnClickListener {
            openService("Sonarr", getString(R.string.sonarr_url))
        }
        
        findViewById<MaterialCardView>(R.id.card_lidarr).setOnClickListener {
            openService("Lidarr", getString(R.string.lidarr_url))
        }
        
        findViewById<MaterialCardView>(R.id.card_readarr).setOnClickListener {
            openService("Readarr", getString(R.string.readarr_url))
        }

        // Downloads
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
EOF

echo "🌐 Creating WebViewActivity..."

# Create WebViewActivity.kt
cat > app/src/main/java/com/garuda/mediastack/WebViewActivity.kt << 'EOF'
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
EOF

echo "🌐 Creating WebView layout..."

# Create WebView activity layout
cat > app/src/main/res/layout/activity_webview.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/background_dark">

    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

    <ProgressBar
        android:id="@+id/progress_bar"
        style="?android:attr/progressBarStyleHorizontal"
        android:layout_width="match_parent"
        android:layout_height="4dp"
        android:layout_alignParentTop="true"
        android:progressTint="@color/accent"
        android:visibility="gone" />

</RelativeLayout>
EOF

echo "🎨 Creating themes..."

# Create themes.xml
cat > app/src/main/res/values/themes.xml << 'EOF'
<resources xmlns:tools="http://schemas.android.com/tools">
    <!-- Base application theme -->
    <style name="Theme.GarudaMediaStack" parent="Theme.Material3.DayNight.NoActionBar">
        <!-- Customize your theme here -->
        <item name="colorPrimary">@color/accent</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorPrimaryContainer">@color/card_background</item>
        <item name="colorOnPrimaryContainer">@color/text_primary</item>
        
        <item name="android:colorBackground">@color/background_dark</item>
        <item name="colorOnBackground">@color/text_primary</item>
        <item name="colorSurface">@color/card_background</item>
        <item name="colorOnSurface">@color/text_primary</item>
        
        <!-- Status bar -->
        <item name="android:statusBarColor">@color/background_dark</item>
        <item name="android:windowLightStatusBar">false</item>
        
        <!-- Navigation bar -->
        <item name="android:navigationBarColor">@color/background_dark</item>
    </style>
</resources>
EOF

echo "🔧 Creating additional configuration files..."

# Create gradle.properties
cat > gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
EOF

# Create settings.gradle
cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "Garuda Media Stack"
include ':app'
EOF

echo "📱 Creating app build script..."

# Create app build script
cat > build-app.sh << 'EOF'
#!/bin/bash

echo "🔨 Building Garuda Media Stack Android App..."

# Check for Android SDK
if [ -z "$ANDROID_HOME" ]; then
    echo "⚠️ ANDROID_HOME not set. Please set your Android SDK path."
    echo "Example: export ANDROID_HOME=/path/to/android-sdk"
    exit 1
fi

# Clean and build
echo "🧹 Cleaning project..."
./gradlew clean

echo "🔨 Building debug APK..."
./gradlew assembleDebug

echo "📦 Building release APK..."
./gradlew assembleRelease

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📱 APK Files created:"
    echo "  Debug: app/build/outputs/apk/debug/app-debug.apk"
    echo "  Release: app/build/outputs/apk/release/app-release-unsigned.apk"
    echo ""
    echo "🔧 To install debug APK:"
    echo "  adb install app/build/outputs/apk/debug/app-debug.apk"
    echo ""
    echo "📺 For Android TV/Fire TV:"
    echo "  adb connect [DEVICE_IP]:5555"
    echo "  adb install app/build/outputs/apk/debug/app-debug.apk"
else
    echo "❌ Build failed!"
    exit 1
fi
EOF

chmod +x build-app.sh

echo "📋 Creating README..."

# Create README for the app
cat > README.md << 'EOF'
# Garuda Media Stack Android/Fire TV App

A unified Android application to access your complete Garuda Media Stack from Android devices and Fire TV.

## Features

📱 **Universal Access**: Single app for all your media services
🎬 **Media Streaming**: Direct access to Jellyfin media server  
📚 **Lou's Library**: Browse and read your complete book collection
📋 **Content Management**: Add movies/TV shows via Radarr/Sonarr
⬇️ **Download Monitoring**: Check qBittorrent and Jackett status
📺 **TV Optimized**: Designed for Android TV and Fire TV devices
🎮 **Remote Control**: Full D-pad and remote control support

## Services Included

### Media Servers
- **Jellyfin** (Port 8096) - Stream movies, TV shows, music
- **Lou's Library** (Port 8083) - Browse thousands of books

### Content Management  
- **Radarr** (Port 7878) - Movie automation
- **Sonarr** (Port 8989) - TV show automation
- **Lidarr** (Port 8686) - Music automation
- **Readarr** (Port 8787) - Book automation

### Downloads & Search
- **qBittorrent** (Port 5080) - Download client
- **Jackett** (Port 9117) - Torrent indexer search

## Installation

### Prerequisites
- Android SDK
- Android Studio (optional)
- Device with Android 5.0+ (API 21+)

### Building the App

```bash
# Set Android SDK path
export ANDROID_HOME=/path/to/android-sdk

# Build the app
./build-app.sh
```

### Installing on Device

```bash
# Install debug version
adb install app/build/outputs/apk/debug/app-debug.apk

# For Android TV/Fire TV
adb connect [DEVICE_IP]:5555
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Configuration

The app is pre-configured to connect to:
- **Server IP**: 192.168.12.172
- **All service ports**: As defined in your media stack

To change the server IP, edit `app/src/main/res/values/strings.xml`

## Usage

1. **Launch App**: Open "Garuda Media Stack" on your device
2. **Select Service**: Tap any service card to open it
3. **Navigate**: Use touch or D-pad to navigate web interfaces
4. **Go Back**: Use back button or remote to return to main menu

### Android TV/Fire TV

- Use D-pad to navigate service cards
- Press OK/Select to open services
- Use back button to return to main menu
- All services optimized for TV viewing

## Development

### Project Structure
```
app/
├── src/main/
│   ├── java/com/garuda/mediastack/
│   │   ├── MainActivity.kt          # Main service launcher
│   │   └── WebViewActivity.kt       # Service web interface
│   ├── res/
│   │   ├── layout/                  # UI layouts
│   │   ├── values/                  # Strings, colors, styles
│   │   └── drawable/                # Icons and graphics
│   └── AndroidManifest.xml
├── build.gradle                     # App dependencies
└── proguard-rules.pro
```

### Adding New Services

1. Add service URL to `strings.xml`
2. Add service card to `activity_main.xml`  
3. Add click listener in `MainActivity.kt`
4. Build and test

## Troubleshooting

### Connection Issues
- Verify device is on same network as media stack
- Check firewall settings on server
- Ensure all services are running

### Android TV Issues
- Enable "Apps from unknown sources" 
- Use adb to install if Google Play unavailable
- Ensure TV is in developer mode for debugging

### Build Issues
- Verify ANDROID_HOME is set correctly
- Check Android SDK tools are installed
- Use Android Studio for detailed error logs

## Support

For issues with:
- **Media Stack Setup**: Check main repository documentation
- **Android App**: Create issue with device/Android version details
- **Service Configuration**: Verify service URLs and ports

---

🚀 **Your complete media stack now available on any Android device!**
EOF

cd ../../

echo "✅ ANDROID/FIRETV APP CREATED SUCCESSFULLY!"
echo ""
echo "📱 WHAT WAS CREATED:"
echo "  📂 mobile-app/GarudaMediaStack/ - Complete Android Studio project"
echo "  🎨 Modern Material Design UI optimized for TV"
echo "  🌐 WebView integration for all services"
echo "  📺 Android TV/Fire TV support with D-pad navigation"
echo "  🔨 build-app.sh - Automated build script"
echo ""
echo "🎯 SERVICES INCLUDED:"
echo "  🎬 Jellyfin (Media streaming)"
echo "  📚 Lou's Library (Book collection)"
echo "  📋 Radarr, Sonarr, Lidarr, Readarr (Content management)"
echo "  ⬇️ qBittorrent, Jackett (Downloads & search)"
echo ""
echo "🚀 NEXT STEPS:"
echo "  1. cd mobile-app/GarudaMediaStack/"
echo "  2. Set ANDROID_HOME environment variable"
echo "  3. Run ./build-app.sh to build APK"
echo "  4. Install on Android device or Fire TV"
echo ""
echo "📱 YOUR COMPLETE MEDIA STACK IS NOW AVAILABLE ON ANDROID/FIRE TV!"
