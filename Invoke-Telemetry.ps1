<#
.SYNOPSIS
    Tool to track CPU, RAM and GPU usage.
.NOTES
    File Name      : Invoke-Telemetry.ps1
    Prerequisites   : PowerShell v5.1, Nvidia GeForce
    Author        : Antoine Cauchois
#>

$nvidiaSMIPath = Join-Path -Path $Env:ProgramFiles -ChildPath 'NVIDIA Corporation\NVSMI\nvidia-smi.exe'
$desktopPath = Join-Path -Path $Env:USERPROFILE -ChildPath 'Desktop'
$outFilePath = Join-Path -Path $desktopPath -ChildPath ([string]([string]::Concat([string](Get-Date -Format "yyyyMMdd"), "-Telemetry.csv")))
$timer = [Diagnostics.Stopwatch]::StartNew()

If (-not (Test-Path -Path $nvidiaSMIPath)) {
    Write-Error -Message "$nvidiaSMIPath cannot be found." -Category ObjectNotFound -ErrorAction Stop
}

If (Test-Path -Path $outFilePath) {
    Write-Error -Message "$outFilePath already exist." -Category ResourceExists -ErrorAction Stop
}

While ($timer.Elapsed.TotalHours -lt 2) {
    $cpuUsage = (Get-WmiObject -Class win32_processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average | Select-Object Average).Average

    $computerMemory = Get-WmiObject -Class win32_operatingsystem -ErrorAction Stop
    $memoryUsage = ((($computerMemory.TotalVisibleMemorySize - $computerMemory.FreePhysicalMemory) * 100) / $computerMemory.TotalVisibleMemorySize)
    try {
        $gpuUsage = Invoke-Expression -Command "& '$nvidiaSMIPath' --query-gpu=utilization.gpu --format=csv,noheader,nounits"
    } catch {
        Write-Error -Message "An error has occured during nvidiaSMI execution." -ErrorAction Stop
    }

    $lineOutput = New-Object -type PSCustomObject
    $lineOutput | Add-Member -Type NoteProperty -Name 'Time' -Value $timer.Elapsed
    $lineOutput | Add-Member -Type NoteProperty -Name 'CPU %' -Value $cpuUsage
    $lineOutput | Add-Member -Type NoteProperty -Name 'RAM %' -Value $memoryUsage
    $lineOutput | Add-Member -Type NoteProperty -Name 'GPU %' -Value $gpuUsage

    $lineOutput | Export-Csv -Path $outFilePath -Delimiter ';' -Append -NoTypeInformation

    Start-Sleep -Seconds 10
    [System.GC]::Collect()
}