-- fstream.scpt - AppleScript Interface to FStream
--
-- Version: 0.5
-- Written by Aaron Blakely <aaron@ephasic.org>
-- Distributed as part of FStreamServer:
--  http://github.com/ablakely/FStreamServer
--
-- Copyright 2019 (C) Aaron Blakely

on run argv
	set stdout to ""
	set currentTitle to ""
	set currentAlbum to ""
	set currentArtist to ""
	set currentURL to ""

	tell application "FStream"
		repeat with t in argv
			if "getUser" is in t then
				set stdout to stdout & short user name of (system info)
			else if "start" is in t then
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
