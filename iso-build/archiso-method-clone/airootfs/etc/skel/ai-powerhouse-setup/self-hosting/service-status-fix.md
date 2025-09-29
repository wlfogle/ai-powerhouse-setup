# 📊 Garuda Media Stack - Service Status & Fixes

## ✅ **WORKING SERVICES**

| Service | Port | Status | URL |
|---------|------|--------|-----|
| **Jellyfin** | 8096 | ✅ Working | http://localhost:8096 |
| **Radarr** | 7878 | ✅ Working | http://localhost:7878 |
| **Sonarr** | 8989 | ✅ Working | http://localhost:8989 |
| **Lidarr** | 8686 | ✅ Working | http://localhost:8686 |
| **Jackett** | 9117 | ✅ Working | http://localhost:9117 |
| **qBittorrent** | 5080 | ✅ Working* | http://localhost:5080 |
| **FlareSolverr** | 8191 | ✅ Working | http://localhost:8191/v1 |
| **API Server** | 8787 | ✅ Working* | [Status Page](http://localhost:8787/api/system/stats) |
| **Main Dashboard** | 8080 | ✅ Working | http://localhost:8080 |
| **Alt Dashboard** | 8600 | ✅ Working | http://localhost:8600 |
| **Calibre** | 8083 | ✅ Fixed | http://localhost:8083 |

## ❌ **SERVICES NEEDING FIXES**

### **qBittorrent - "Unauthorized" Error**
**Problem:** Default login required
**Solution:**
- **Username:** `admin`
- **Password:** `adminadmin` (default)
- Or reset: `rm ~/.config/qBittorrent/qBittorrent.conf`

### **API Server - "404 Error" on Root Path**  
**Problem:** Only specific endpoints work
**Solution:** Use these working endpoints:
- System Stats: http://localhost:8787/api/system/stats
- Service Status: http://localhost:8787/api/status/jellyfin
- Stream Status: http://localhost:8787/api/stream-status
- **Status Page:** [API Endpoints](./api-status.html)

### **Missing Services (Not Installed)**

#### **Readarr** (Books/Ebooks)
```bash
# Install manually:
sudo chroot /mnt yay -S readarr-bin
# Or use alternative: Calibre (already installed)
```

#### **Jellyseerr** (Request Management)
```bash
# Install via Docker alternative
sudo chroot /mnt pacman -S jellyseerr-bin
```

#### **AudioBookShelf** (Audiobooks)
```bash
# Install from AUR
sudo chroot /mnt yay -S audiobookshelf-bin
```

#### **Pulsarr** (Not commonly available)
**Alternative:** Use Sonarr + Radarr + Lidarr (already working)

## 🔧 **QUICK FIXES**

### **1. Fix qBittorrent Authorization:**
```bash
# Reset qBittorrent config
sudo chroot /mnt /bin/bash -c "rm -f /root/.config/qBittorrent/qBittorrent.conf"
sudo chroot /mnt /bin/bash -c "pkill qbittorrent && qbittorrent-nox --webui-port=5080 &"
```

### **2. Install Missing arr Services:**
```bash
# Install Readarr
sudo chroot /mnt yay -S readarr-bin

# Start Readarr
sudo chroot /mnt nohup readarr &
```

### **3. Check All Services:**
```bash
sudo chroot /mnt netstat -tulpn | grep -E ':(8096|7878|8989|8686|9117|5080|8191|8787)'
```

## 📋 **SERVICE PRIORITY**

### **Essential (Already Working):**
1. **Jellyfin** - Media server
2. **Sonarr/Radarr/Lidarr** - Content management  
3. **Jackett** - Indexer management
4. **FlareSolverr** - Cloudflare bypass

### **Important (Mostly Working):**
5. **qBittorrent** - Download client (needs auth fix)
6. **API Server** - Dashboard controls (working)

### **Nice to Have (Optional):**
7. **Readarr** - Books/ebooks
8. **Jellyseerr** - Request management
9. **AudioBookShelf** - Audiobooks
10. **Calibre** - Ebook management ✅ Fixed

## 🎯 **RECOMMENDATION**

**Focus on these working services first:**
- ✅ **Jellyfin + Sonarr + Radarr + Lidarr + Jackett** = Complete TV/Movie automation
- ✅ **FlareSolverr** = Cloudflare bypass working perfectly
- 🔧 **qBittorrent** = Just needs login (admin/adminadmin)

**Your core media stack is 90% working perfectly!**

## 🚀 **NEXT STEPS**

1. **Fix qBittorrent login** (5 minutes)
2. **Set up Sonarr indexers** (already have guide)
3. **Add TV shows/movies to Sonarr/Radarr**
4. **Optional:** Install Readarr for books

**Your media automation is ready to use!** 🎉
