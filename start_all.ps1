Write-Host "Starting Myrka services..." -ForegroundColor Green
if (!(Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" }
Start-Process -NoNewWindow -FilePath "cmd" -ArgumentList "/c cd backend && npm start > ..\logs\backend.log 2>&1"
Start-Sleep -Seconds 3
Start-Process -NoNewWindow -FilePath "cmd" -ArgumentList "/c cd frontend && npm run dev > ..\logs\frontend.log 2>&1"
Start-Sleep -Seconds 3
if (Get-Command ngrok -ErrorAction SilentlyContinue) {
    Start-Process -NoNewWindow -FilePath "cmd" -ArgumentList "/c ngrok http 3000 > ..\logs\ngrok.log 2>&1"
}
Start-Process "http://localhost:3000"
Start-Process "http://localhost:5173"
Write-Host "Services started. Use stop_all.bat to stop."