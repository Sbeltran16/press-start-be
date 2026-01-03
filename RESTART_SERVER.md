# Restart Rails Server for Mobile Development

The Rails server needs to be restarted to apply network binding changes.

## Steps to Restart:

1. **Stop the current server** (if running):
   - Press `Ctrl+C` in the terminal where Rails is running
   - Or kill the process: `kill $(lsof -t -i:3001)`

2. **Start the server**:
   ```bash
   cd press-start-be
   rails server
   ```

3. **Verify it's accessible**:
   - On your computer: `curl http://localhost:3001/up`
   - On your iPhone: Open Safari and go to `http://172.20.10.2:3001/up`
   - Both should return `{"status":"ok"}` quickly

## Troubleshooting:

- **If still slow**: Check database connection and queries
- **If can't connect from iPhone**: 
  - Verify both devices are on same Wi-Fi network
  - Check Mac firewall settings
  - Verify IP address: `ifconfig | grep "inet " | grep -v 127.0.0.1`
