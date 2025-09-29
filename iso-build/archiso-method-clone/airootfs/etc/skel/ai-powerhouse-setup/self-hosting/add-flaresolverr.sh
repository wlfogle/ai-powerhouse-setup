
# Add FlareSolverr to Garuda Media Stack
# Run this after booting into your main system

echo '🔥 Adding FlareSolverr to Garuda Media Stack...'

# Check if FlareSolverr is already running
if podman ps | grep -q flaresolverr; then
    echo '✅ FlareSolverr is already running'
    podman ps | grep flaresolverr
    exit 0
fi

echo 'Starting FlareSolverr container...'
podman run -d   --name garuda-media-stack-flaresolverr   --network host   -p 8191:8191   -e LOG_LEVEL=info   -e LOG_HTML=false   -e CAPTCHA_SOLVER=none   --restart unless-stopped   docker.io/flaresolverr/flaresolverr:latest

if [ $? -eq 0 ]; then
    echo '✅ FlareSolverr started successfully!'
    echo ''
    echo '🔧 NEXT STEPS:'
    echo '1. Open Jackett: http://192.168.12.172:9117'
    echo '2. Go to Settings (gear icon)'
    echo '3. Set FlareSolverr URL: http://192.168.12.172:8191'
    echo '4. Save settings'
    echo ''
    echo '🎯 FlareSolverr is now available at: http://192.168.12.172:8191'
else
    echo '❌ FlareSolverr failed to start'
    exit 1
fi
