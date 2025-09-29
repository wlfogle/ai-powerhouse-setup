# Sonarr Indexer Configuration Guide
## Garuda Media Stack - TV Show Indexers

### 🎯 **Recommended Indexers for Sonarr**

---

## 📺 **TORRENT INDEXERS (via Jackett)**

### **Primary Setup Method:**
1. **Go to Sonarr**: http://localhost:8989
2. **Settings** → **Indexers** → **Add Indexer** → **Torznab**
3. **Use these configurations:**

---

### **✅ TOP RECOMMENDED - TV FOCUSED**

#### **1. EZTV (TV Shows Specialist)**
- **Name**: EZTV
- **URL**: `http://localhost:9117/api/v2.0/indexers/eztv/results/torznab/`
- **API Key**: `fu0rbrfo1xfc7heii08c0ay9m9wca27y`
- **Categories**: 5000,5030,5040 (TV)
- **Notes**: Best for TV shows, very reliable

#### **2. TorrentGalaxy (All Content)**
- **Name**: TorrentGalaxy
- **URL**: `http://localhost:9117/api/v2.0/indexers/torrentgalaxy/results/torznab/`
- **API Key**: `fu0rbrfo1xfc7heii08c0ay9m9wca27y`
- **Categories**: 5000,5030,5040 (TV)
- **Notes**: Excellent for new releases

#### **3. 1337x (Popular Content)**
- **Name**: 1337x
- **URL**: `http://localhost:9117/api/v2.0/indexers/1337x/results/torznab/`
- **API Key**: `fu0rbrfo1xfc7heii08c0ay9m9wca27y`
- **Categories**: 5000,5030,5040 (TV)
- **Notes**: Uses FlareSolverr automatically

---

### **✅ SECONDARY OPTIONS - GOOD BACKUPS**

#### **4. LimeTorrents**
- **Name**: LimeTorrents
- **URL**: `http://localhost:9117/api/v2.0/indexers/limetorrents/results/torznab/`
- **API Key**: `fu0rbrfo1xfc7heii08c0ay9m9wca27y`
- **Categories**: 5000,5030,5040

#### **5. Torlock**
- **Name**: Torlock
- **URL**: `http://localhost:9117/api/v2.0/indexers/torlock/results/torznab/`
- **API Key**: `fu0rbrfo1xfc7heii08c0ay9m9wca27y`
- **Categories**: 5000,5030,5040

---

## 🌐 **USENET INDEXERS (Premium)**

### **If you have Usenet subscriptions:**

#### **NZBGeek (Recommended)**
- **Type**: Newznab
- **URL**: `https://api.nzbgeek.info`
- **API Key**: Your NZBGeek API key
- **Categories**: 5000,5030,5040

#### **NZBHydra2 (Aggregator)**
- **Type**: Newznab  
- **URL**: `http://localhost:5076` (if installed)
- **API Key**: Your NZBHydra2 key

---

## ⚙️ **STEP-BY-STEP SETUP**

### **Step 1: Add Jackett Indexers to Sonarr**

1. **Open Sonarr**: http://localhost:8989
2. **Go to**: Settings → Indexers
3. **Click**: Add Indexer → Torznab
4. **Fill in**:
   ```
   Name: EZTV
   URL: http://localhost:9117/api/v2.0/indexers/eztv/results/torznab/
   API Key: fu0rbrfo1xfc7heii08c0ay9m9wca27y
   ```
5. **Click**: Test → Save
6. **Repeat** for other indexers

### **Step 2: Configure Categories**
- **TV**: 5000,5030,5040
- **TV/HD**: 5040  
- **TV/SD**: 5030
- **Anime**: 5070

### **Step 3: Set Priority**
1. **EZTV**: Priority 1 (highest)
2. **TorrentGalaxy**: Priority 2
3. **1337x**: Priority 3
4. **Others**: Priority 10+

---

## 🎯 **OPTIMAL TV CATEGORIES**

```
Standard TV: 5000
TV/Web-DL: 5030
TV/HD: 5040
TV/UHD: 5045
Anime: 5070
```

---

## 🔧 **TROUBLESHOOTING**

### **If indexer fails:**
1. **Check Jackett**: http://localhost:9117
2. **Test indexer** in Jackett first
3. **Verify FlareSolverr**: http://localhost:8191/v1
4. **Check API key** is correct

### **Common Issues:**
- **SSL errors**: Use our fix script
- **Cloudflare blocks**: FlareSolverr handles automatically
- **No results**: Check categories match content type

---

## 🚀 **QUICK SETUP COMMANDS**

```bash
# Test Jackett indexers
sudo chroot /mnt /home/lou/github/garuda-media-stack/fix-jackett-ssl.sh test

# Check FlareSolverr status
sudo chroot /mnt /opt/FlareSolverr/start_flaresolverr.sh status

# View recommended indexers
sudo chroot /mnt /home/lou/github/garuda-media-stack/fix-jackett-ssl.sh alternatives
```

---

## 📊 **PRIORITY RANKING FOR TV SHOWS**

1. **🥇 EZTV** - TV specialist, most reliable
2. **🥈 TorrentGalaxy** - Great for new releases  
3. **🥉 1337x** - Popular content, good variety
4. **LimeTorrents** - Solid backup option
5. **Torlock** - Verified torrents

---

## ⚡ **PRO TIPS**

- ✅ **Use multiple indexers** for redundancy
- ✅ **EZTV first** for TV shows (specialist site)
- ✅ **TorrentGalaxy second** for quality releases
- ✅ **FlareSolverr handles** Cloudflare automatically
- ✅ **Categories matter** - use TV categories only
- ✅ **Test each indexer** in Jackett before adding to Sonarr

**Your TV show automation will be incredibly reliable with this setup!** 📺🎉
