on run argv
	set stdout to ""
	set currentTitle to ""
	set currentAlbum to ""
	set currentArtist to ""
	set currentURL to ""
	
	tell application "FStream"
		repeat with t in argv
			if "start" is in t then
				set stdout to stdout & "Starting FStream Player..."
				startPlaying
			else if "stop" is in t then
				set stdout to stdout & "Stopping FStream Player..."
				stopPlaying
			else if "np" is in t then
				set currentTitle to playingTitle
				set currentArtist to playingArtist
				set currentAlbum to playingAlbum
				set currentURL to playingURL
				
				set stdout to stdout & currentTitle & ":" & currentArtist & ":" & currentAlbum & ":" & currentURL
			end if
		end repeat
	end tell
	copy stdout to stdout
end run

