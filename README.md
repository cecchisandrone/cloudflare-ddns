# cloudflare-ddns
DIY DDNS for DNS hosted on Cloudflare

Important: This requires `dig` to be installed. If not run `sudo apt-get install dnsutils`

## How to run with Cron
Create `/etc/cron.d/dns-update` file with the following content: 
```
*/30 * * * * pi /home/pi/cloudflare-ddns/dns-update.sh <<ZONE-ID>> <<RECORD-ID>> <<DNS>> <<AUTH_EMAIL>> <<AUTH_KEY>>
```
This will run every 30 minutes and update the given DNS on Cloudflare, pointing to your current public IP
