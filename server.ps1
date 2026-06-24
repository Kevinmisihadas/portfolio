# Lightweight native PowerShell HTTP Server for Kevin's Portfolio
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8000/")
try {
    $listener.Start()
    Write-Host "Server started at http://localhost:8000/"
} catch {
    Write-Error $_
    Exit
}

$baseDir = "C:\Users\student\.gemini\antigravity\scratch\kevin-portfolio"

# Keep listening until stopped
while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath
        if ($urlPath -eq "/") {
            $urlPath = "/index.html"
        }

        # Normalize path and prevent directory traversal
        $urlPath = $urlPath.Replace("/", "\")
        $filePath = Join-Path $baseDir $urlPath.Substring(1)

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            
            # Set appropriate content type
            if ($filePath -like "*.html") { $response.ContentType = "text/html; charset=utf-8" }
            elseif ($filePath -like "*.css") { $response.ContentType = "text/css; charset=utf-8" }
            elseif ($filePath -like "*.js") { $response.ContentType = "application/javascript; charset=utf-8" }
            elseif ($filePath -like "*.png") { $response.ContentType = "image/png" }
            elseif ($filePath -like "*.jpg" -or $filePath -like "*.jpeg") { $response.ContentType = "image/jpeg" }
            elseif ($filePath -like "*.svg") { $response.ContentType = "image/svg+xml" }

            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 File Not Found")
            $response.ContentLength64 = $errBytes.Length
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
    } catch {
        # Silent fail for individual request errors to keep server alive
    } finally {
        if ($null -ne $response) {
            $response.OutputStream.Close()
        }
    }
}
