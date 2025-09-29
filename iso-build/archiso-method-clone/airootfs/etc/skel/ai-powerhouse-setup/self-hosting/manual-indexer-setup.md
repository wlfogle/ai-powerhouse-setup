# Manual Jackett Indexer Setup for *arr Services

If automatic configuration didn't work, manually add Jackett indexers:

## 1. Jackett Setup
- Go to: http://localhost:9117
- Add popular public indexers:
  - 1337x, The Pirate Bay, RARBG, LimeTorrents, TorrentGalaxy
  - EZTV (for TV), YTS (for movies)
- Copy Jackett API key from settings

## 2. Radarr (Movies) - http://localhost:7878
- Settings → Indexers → Add (+) → Torznab
- Name: Jackett (All)
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/
- API Key: [Jackett API Key]
- Categories: 2000,2010,2020,2030,2040,2050,2060,2070,2080

## 3. Sonarr (TV) - http://localhost:8989
- Settings → Indexers → Add (+) → Torznab  
- Name: Jackett (All)
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/
- API Key: [Jackett API Key]
- Categories: 5000,5010,5020,5030,5040,5050

## 4. Lidarr (Music) - http://localhost:8686
- Settings → Indexers → Add (+) → Torznab
- Name: Jackett (All) 
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/
- API Key: [Jackett API Key]
- Categories: 3000,3010,3020,3030,3040

## 5. Readarr (Books) - http://localhost:8787
- Settings → Indexers → Add (+) → Torznab
- Name: Jackett (All)
- URL: http://localhost:9117/api/v2.0/indexers/all/results/torznab/ 
- API Key: [Jackett API Key]
- Categories: 7000,7010,7020,8000,8010
