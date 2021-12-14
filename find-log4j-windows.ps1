# Finds log4j resources on Windows machines
# by Christian Blechert <christian@serverless.industries>

Add-Type -assembly "system.io.compression.filesystem"

gwmi win32_volume | where-object { $_.filesystem -match "ntfs" -and $_.name -match "^[A-Z]:" } | sort { $_.name } | foreach-object {

	Get-ChildItem $_.name -File -Recurse -erroraction 'silentlycontinue' |
		Where-Object { $_.Name -match '\.jar$' } |
		Select-Object -ExpandProperty FullName |
			Foreach-Object {
				$folder = $_
				$containsLog = ([io.compression.zipfile]::OpenRead($folder).Entries |
					Where-Object { $_.FullName -match "^org/apache/(log4j|logging/log4j)" }).Length

				if ( $containsLog -gt 0 ) {
					Write-Host "$($folder)"
				}
			}

}
if($args[0] -ne "nopause"){
	pause
}
# eof
