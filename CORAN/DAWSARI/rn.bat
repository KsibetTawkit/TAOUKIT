Get-ChildItem *.mp3 | ForEach-Object {
    $new = "$($_.Name.Substring(0,3)).mp3"
    Rename-Item $_.FullName -NewName $new
}

