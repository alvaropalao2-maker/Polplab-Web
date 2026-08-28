param(
  [Parameter(Mandatory=$true)][string]$Url,
  [Parameter(Mandatory=$true)][string]$Out,
  [int]$Width = 1440,
  [int]$Port = 9333
)

$ErrorActionPreference = "Stop"
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$udd = Join-Path $env:TEMP ("cdpshot_" + [guid]::NewGuid().ToString("N"))

$eargs = @(
  "--headless=new","--disable-gpu","--hide-scrollbars","--force-device-scale-factor=1",
  "--force-prefers-reduced-motion","--mute-audio","--no-first-run","--no-default-browser-check",
  "--remote-debugging-port=$Port","--user-data-dir=$udd","about:blank"
)
$proc = Start-Process -FilePath $edge -ArgumentList $eargs -PassThru -WindowStyle Hidden

function Wait-Endpoint($port) {
  for ($i = 0; $i -lt 60; $i++) {
    try { return (Invoke-RestMethod "http://127.0.0.1:$port/json/version" -TimeoutSec 2) } catch { Start-Sleep -Milliseconds 250 }
  }
  throw "DevTools endpoint never came up on $port"
}

$ws = $null
try {
  Wait-Endpoint $Port | Out-Null
  $targets = Invoke-RestMethod "http://127.0.0.1:$Port/json/list" -TimeoutSec 5
  $page = $targets | Where-Object { $_.type -eq "page" } | Select-Object -First 1
  if (-not $page) { throw "no page target" }
  $wsUrl = $page.webSocketDebuggerUrl

  $ws = New-Object System.Net.WebSockets.ClientWebSocket
  $ct = [System.Threading.CancellationToken]::None
  $ws.ConnectAsync([Uri]$wsUrl, $ct).Wait()

  $script:mid = 0
  function Send-Cmd($method, $params) {
    $script:mid++
    $msg = @{ id = $script:mid; method = $method }
    if ($params) { $msg.params = $params }
    $json = $msg | ConvertTo-Json -Depth 20 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $seg = New-Object System.ArraySegment[byte] (,$bytes)
    $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).Wait()
    return $script:mid
  }
  function Recv-Until($wantId) {
    $buf = New-Object byte[] 1048576
    while ($true) {
      $sb = New-Object System.Text.StringBuilder
      do {
        $seg = New-Object System.ArraySegment[byte] (,$buf)
        $res = $ws.ReceiveAsync($seg, $ct)
        $res.Wait()
        [void]$sb.Append([System.Text.Encoding]::UTF8.GetString($buf, 0, $res.Result.Count))
      } while (-not $res.Result.EndOfMessage)
      $obj = $sb.ToString() | ConvertFrom-Json
      if ($obj.id -eq $wantId) { return $obj }
    }
  }
  function Call($method, $params) {
    $id = Send-Cmd $method $params
    return Recv-Until $id
  }

  Call "Page.enable" $null | Out-Null
  Call "Runtime.enable" $null | Out-Null
  Call "Network.enable" $null | Out-Null
  Call "Emulation.setDeviceMetricsOverride" @{ width = $Width; height = 1000; deviceScaleFactor = 1; mobile = $false } | Out-Null

  # navigate
  Call "Page.navigate" @{ url = $Url } | Out-Null
  Start-Sleep -Seconds 3

  # scroll through the page to trigger lazy content / ScrollTrigger, then back to top
  $js = @'
new Promise(async (resolve) => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  await sleep(400);
  const h = () => Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);
  let y = 0;
  const step = Math.round(window.innerHeight * 0.8);
  while (y < h()) {
    window.scrollTo(0, y);
    window.dispatchEvent(new Event('scroll'));
    await sleep(120);
    y += step;
  }
  window.scrollTo(0, h());
  await sleep(500);
  window.scrollTo(0, 0);
  window.dispatchEvent(new Event('scroll'));
  await sleep(600);
  // force any lingering opacity animations to completion
  try {
    document.querySelectorAll('[style*="opacity"]').forEach(el => {
      const o = parseFloat(el.style.opacity);
      if (!isNaN(o) && o < 1) el.style.opacity = '';
    });
    if (window.gsap) { window.gsap.globalTimeline.progress(1); }
  } catch(e){}
  await sleep(400);
  resolve(h());
});
'@
  $r = Call "Runtime.evaluate" @{ expression = $js; awaitPromise = $true; returnByValue = $true }
  $fullH = [int]$r.result.result.value
  if ($fullH -lt 400) { $fullH = 9000 }

  Call "Emulation.setDeviceMetricsOverride" @{ width = $Width; height = $fullH; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Start-Sleep -Milliseconds 800

  $shot = Call "Page.captureScreenshot" @{ format = "png"; captureBeyondViewport = $true; fromSurface = $true }
  $b64 = $shot.result.data
  [System.IO.File]::WriteAllBytes($Out, [Convert]::FromBase64String($b64))
  Write-Output ("OK {0} fullH={1}" -f $Out, $fullH)
}
finally {
  if ($ws) { try { $ws.Dispose() } catch {} }
  if ($proc -and -not $proc.HasExited) { try { $proc.Kill() } catch {} }
  Get-ChildItem $udd -ErrorAction SilentlyContinue | Out-Null
  try { Remove-Item $udd -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}
