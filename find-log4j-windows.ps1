# Finds log4j resources on Windows machines
# by Christian Blechert <christian@serverless.industries>

Add-Type -assembly "system.io.compression.filesystem"

Write-Host "detected = reliable detection of log4j2"
Write-Host "guess = log4j1, the bundle version field from the manifest"
Write-Host "unsure = the implementation version field from the manifest"
Write-Host ""

# Iterate disk drives
gwmi win32_volume | where-object { $_.filesystem -match "ntfs" -and $_.name -match "^[A-Z]:" } | sort { $_.name } | foreach-object {

	# find all *.jar files
	Get-ChildItem $_.name -File -Recurse -erroraction 'silentlycontinue' |
		Where-Object { $_.Name -match '\.jar$' } |
		Select-Object -ExpandProperty FullName |
			Foreach-Object {
				$folder = $_

				# open and look for log4j
				$zip = [io.compression.zipfile]::OpenRead($folder)
				$containsLog = ($zip.Entries |
					Where-Object { $_.FullName -match "^org/apache/(log4j|logging/log4j)" }).Length

				if ( $containsLog -gt 0 ) {
					# extract version from manifest
					$metaInf = $zip.Entries | Where-Object { $_.FullName -eq "META-INF/MANIFEST.MF" }
					[System.IO.Compression.ZipFileExtensions]::ExtractToFile($metaInf[0], "$PSScriptRoot\_MANIFEST.MF", $true)

					$version = "Version unknown"
					if (((get-content "$PSScriptRoot\_MANIFEST.MF" | where-object { $_ -match "^Log4jReleaseVersion:" }) -match '^[^:]+:\s*(.*)$')) {
						$version = "$($Matches[1]) (detected log4j2)"
					} elseif (((get-content "$PSScriptRoot\_MANIFEST.MF" | where-object { $_ -match "^Bundle-Version:" }) -match '^[^:]+:\s*(.*)$')) {
						$version = "$($Matches[1]) (guess log4j1)"
					} elseif (((get-content "$PSScriptRoot\_MANIFEST.MF" | where-object { $_ -match "^Implementation-Version:" }) -match '^[^:]+:\s*(.*)$')) {
						$version = "$($Matches[1]) (unsure)"
					}

					# print hit
					Write-Host "$version`t$($folder)"
				}
			}

}

# pause when script was opened by double click
if ((Get-WmiObject Win32_Process -Filter "ProcessID=$pid").CommandLine -notmatch '\\powershell\.exe"\s*$') {
	Write-Host ""
	pause
}

# eof
