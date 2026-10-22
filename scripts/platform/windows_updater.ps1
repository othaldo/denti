param([string]$JobPath)

# Runs with Windows PowerShell 5.1 / .NET Framework; no separate runtime needed.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$DentiFiles = @('Denti.exe', 'Denti.pck', 'build-info.json')

function Assert-PlainDirectory([string]$Path) {
    $item = [IO.DirectoryInfo]::new([IO.Path]::GetFullPath($Path))
    while ($null -ne $item) {
        if ($item.Exists -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Linked installation/cache directories are not supported.' }
        $item = $item.Parent
    }
}

function Write-UpdateStatus($Job, [string]$State, [string]$Detail = '') {
    $path = Join-Path $Job.WorkDir 'status.json'
    $temporary = $path + '.tmp'
    $json = @{state=$State; detail=$Detail; version=$Job.version} | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($temporary, $json, [Text.UTF8Encoding]::new($false))
    # Readers tolerate a missing/incomplete status while this small file changes.
    if ([IO.File]::Exists($path)) { [IO.File]::Replace($temporary, $path, [NullString]::Value) }
    else { [IO.File]::Move($temporary, $path) }
}

function Read-UpdateJob([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ([IO.Path]::GetFileName($full) -cne 'job.json') { throw 'Invalid update job name.' }
    $job = [IO.File]::ReadAllText($full) | ConvertFrom-Json
    $work = [IO.Path]::GetDirectoryName($full)
    $install = [IO.Path]::GetFullPath([string]$job.install_dir).TrimEnd('\')
    Assert-PlainDirectory $work
    Assert-PlainDirectory $install
    if (-not [IO.Directory]::Exists($install) -or $install -eq [IO.Path]::GetPathRoot($install).TrimEnd('\')) { throw 'Invalid installation directory.' }
    if ($work -ieq $install -or $work.StartsWith($install + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'The cache must be outside the installation.' }
    if ($job.schema_version -ne 1 -or $job.commit -cnotmatch '^[0-9a-f]{40}$' -or $job.sha256 -cnotmatch '^[0-9a-f]{64}$') { throw 'Invalid build/checksum identity.' }
    if ($job.version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[A-Za-z0-9]+(\.[A-Za-z0-9]+)*)?$') { throw 'Invalid release version.' }
    if ($job.channel -notin @('stable', 'beta') -or [long]$job.size -le 0 -or [long]$job.size -gt 536870912) { throw 'Invalid update package.' }
    if ([IO.Path]::GetFullPath([string]$job.archive) -cne (Join-Path $work 'package.zip')) { throw 'Invalid archive location.' }
    foreach ($name in $DentiFiles) {
        $target = Join-Path $install $name
        if (-not [IO.File]::Exists($target) -or ([IO.File]::GetAttributes($target) -band [IO.FileAttributes]::ReparsePoint)) { throw 'The portable installation is incomplete or linked.' }
    }
    foreach ($name in @('.denti-updater.json', '.denti-update.lock')) {
        $internal = Join-Path $install $name
        if ([IO.File]::Exists($internal) -and ([IO.File]::GetAttributes($internal) -band [IO.FileAttributes]::ReparsePoint)) { throw 'Linked updater metadata is not supported.' }
    }
    $current = [IO.File]::ReadAllText((Join-Path $install 'build-info.json')) | ConvertFrom-Json
    if ($current.version -ne $job.current_version -or $current.repository -ne 'othaldo/denti' -or $current.commit.Substring(0,7) -ne $job.current_build -or $current.save_schema -ne $job.save_schema) { throw 'The installed build changed or requires a save migration.' }
    $job | Add-Member NoteProperty WorkDir $work
    $job | Add-Member NoteProperty InstallDir $install
    $job | Add-Member NoteProperty FullJobPath $full
    return $job
}

function Prepare-Update($Job) {
    $inputFile = [IO.File]::OpenRead($Job.archive)
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        $digest = [BitConverter]::ToString($hasher.ComputeHash($inputFile)).Replace('-', '').ToLowerInvariant()
        if ($inputFile.Length -ne $Job.size -or $digest -cne $Job.sha256) { throw 'Update checksum/size mismatch.' }
    } finally { $hasher.Dispose(); $inputFile.Dispose() }
    $archive = [IO.Compression.ZipFile]::OpenRead($Job.archive)
    $stage = $null
    try {
        if ($archive.Entries.Count -ne $DentiFiles.Count) { throw 'Unexpected archive entries.' }
        $seen = @{}
        [long]$total = 0
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -cnotin $DentiFiles -or $seen.ContainsKey($entry.FullName) -or $entry.Length -le 0) { throw 'Unsafe, duplicate or empty archive entry.' }
            if ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) { throw 'Linked archive entry.' }
            $seen[$entry.FullName] = $true
            $total += $entry.Length
        }
        if ($total -gt 1073741824 -or $archive.GetEntry('build-info.json').Length -gt 32768) { throw 'Unpacked update is too large.' }
        # Staging and backups share the installation volume for atomic File.Replace.
        $stage = Join-Path $Job.InstallDir ('.denti-update-' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($stage)
        [void][IO.Directory]::CreateDirectory((Join-Path $stage 'backup'))
        foreach ($entry in $archive.Entries) {
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $stage $entry.FullName))
        }
        $info = [IO.File]::ReadAllText((Join-Path $stage 'build-info.json')) | ConvertFrom-Json
        foreach ($key in @('version', 'commit', 'channel', 'save_schema')) {
            if ($info.$key -cne $Job.$key) { throw 'Archive build identity differs.' }
        }
        if ($info.repository -ne 'othaldo/denti') { throw 'Archive repository differs.' }
        foreach ($pair in @(@('Denti.exe', 'MZ'), @('Denti.pck', 'GDPC'))) {
            $stream = [IO.File]::OpenRead((Join-Path $stage $pair[0]))
            try {
                $bytes = [byte[]]::new($pair[1].Length)
                [void]$stream.Read($bytes, 0, $bytes.Length)
                if ([Text.Encoding]::ASCII.GetString($bytes) -cne $pair[1]) { throw 'Invalid executable/game pack.' }
            } finally { $stream.Dispose() }
        }
        return $stage
    } catch {
        if ($null -ne $stage) { Remove-KnownStage $stage }
        throw
    } finally { $archive.Dispose() }
}

function Restore-UpdateFiles($Job, [string]$Stage) {
    foreach ($name in $DentiFiles) {
        $backup = Join-Path (Join-Path $Stage 'backup') $name
        if ([IO.File]::Exists($backup)) {
            [IO.File]::Replace($backup, (Join-Path $Job.InstallDir $name), [NullString]::Value)
        }
    }
}

function Install-UpdateFiles($Job, [string]$Stage) {
    try {
        foreach ($name in $DentiFiles) {
            [IO.File]::Replace((Join-Path $Stage $name), (Join-Path $Job.InstallDir $name), (Join-Path (Join-Path $Stage 'backup') $name))
        }
    } catch {
        Restore-UpdateFiles $Job $Stage
        throw
    }
}

function Remove-KnownStage([string]$Stage) {
    # No recursive removal: only the three known package files and empty folders.
    if ([IO.Path]::GetFileName($Stage) -cnotmatch '^\.denti-update-[0-9a-f]{32}$') { throw 'Invalid staging directory.' }
    Assert-PlainDirectory $Stage
    foreach ($directory in @((Join-Path $Stage 'backup'), $Stage)) {
        Assert-PlainDirectory $directory
        foreach ($name in $DentiFiles) {
            $file = Join-Path $directory $name
            if ([IO.File]::Exists($file)) { [IO.File]::Delete($file) }
        }
        if ([IO.Directory]::Exists($directory) -and [IO.Directory]::GetFileSystemEntries($directory).Count -eq 0) { [IO.Directory]::Delete($directory) }
    }
}

function Start-Denti($Job, [bool]$Acknowledge) {
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = Join-Path $Job.InstallDir 'Denti.exe'
    $start.WorkingDirectory = $Job.InstallDir
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    if ($Acknowledge) { $start.Arguments = '-- --denti-update-job "' + $Job.FullJobPath + '"' }
    return [Diagnostics.Process]::Start($start)
}

function Invoke-DentiUpdate([string]$Path) {
    $job = $null
    $stage = $null
    $lock = $null
    $installed = $false
    $child = $null
    try {
        $job = Read-UpdateJob $Path
        # A file-share lock serializes helpers for the same portable installation.
        $lock = [IO.File]::Open((Join-Path $job.InstallDir '.denti-update.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
        $parent = [Diagnostics.Process]::GetProcessById([int]$job.parent_pid)
        if ($parent.MainModule.FileName -ine (Join-Path $job.InstallDir 'Denti.exe')) { throw 'The running game does not match this installation.' }
        $stage = Prepare-Update $job
        Write-UpdateStatus $job 'ready'
        if (-not $parent.WaitForExit(90000)) { throw 'The game did not close; nothing was replaced.' }
        Install-UpdateFiles $job $stage
        $installed = $true
        Write-UpdateStatus $job 'restarting'
        $child = Start-Denti $job $true
        $acknowledged = $false
        for ($attempt = 0; $attempt -lt 300; $attempt++) {
            Start-Sleep -Milliseconds 200
            try {
                $status = [IO.File]::ReadAllText((Join-Path $job.WorkDir 'status.json')) | ConvertFrom-Json
                if ($status.state -eq 'started' -and $status.version -eq $job.version) { $acknowledged = $true; break }
            } catch { }
            if ($child.HasExited) { break }
        }
        if (-not $acknowledged) { throw 'The new version did not acknowledge startup.' }
        # Retain one complete previous version; remove its predecessor after success.
        $pointer = Join-Path $job.InstallDir '.denti-updater.json'
        if ([IO.File]::Exists($pointer)) {
            try {
                $previous = [IO.File]::ReadAllText($pointer) | ConvertFrom-Json
                if ($previous.backup -cmatch '^\.denti-update-[0-9a-f]{32}$') { Remove-KnownStage (Join-Path $job.InstallDir $previous.backup) }
            } catch { } # Retaining an older backup is harmless if it is locked.
        }
        [IO.File]::WriteAllText($pointer, (@{backup=[IO.Path]::GetFileName($stage); version=$job.version} | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
        [IO.File]::Delete($job.archive)
        Write-UpdateStatus $job 'complete'
    } catch {
        $detail = $_.Exception.Message
        if ($null -ne $job) {
            try {
                if ($installed) {
                    if ($null -ne $child -and -not $child.HasExited) { $child.Kill(); $child.WaitForExit() }
                    Restore-UpdateFiles $job $stage
                    Write-UpdateStatus $job 'failed' $detail
                    [void](Start-Denti $job $false)
                }
                if ($null -ne $stage) {
                    # Never discard the last good files if rollback itself failed.
                    $remaining = @([IO.Directory]::GetFiles((Join-Path $stage 'backup')))
                    if ($remaining.Count -eq 0) { Remove-KnownStage $stage }
                }
            } catch { $detail += ' Recovery: ' + $_.Exception.Message }
            Write-UpdateStatus $job 'failed' $detail
        }
        exit 1
    } finally {
        if ($null -ne $lock) { $lock.Dispose() }
    }
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-DentiUpdate $JobPath }
