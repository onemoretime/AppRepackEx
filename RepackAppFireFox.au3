#Region Header
; #INDEX# =======================================================================================================================
; Title .............: Firefox repackager
; Filename...........: RepackAppFireFox.au3
; AutoIt Version ....: 3.3++
; Requirements ......: AutoIt v3.3 +
; Uses...............:
; Language ..........: English
; Description .......: Repackaging of FireFox
; Author(s) .........: onemoretime
; Notes .............: submodule of a future Repack.au3
; Available Functions:
;		CheckPrerequisite
;		CleanUpWorkingDir
;		Uncompress
;		Compress
;		Heart
; Remarks............: None
; Related............:
; Link...............: http://mike.kaply.com/2012/02/14/customizing-the-firefox-installer-on-windows-2012/
; Link...............: http://msiworld.blogspot.com.au/2012/01/packaging-mozilla-firefox-901.html
; Link...............: http://howto.gumph.org/content/customize-firefox-installer/
; Link...............: http://www.thedecoderwheel.com/?p=1329
; Todo...............: quite all the stuff
; Example............: Yes. See RepackAppFireFox_Test.au3
; ===============================================================================================================================

; Repack directives for FF
#cs
autoconf ? autoconfig.cfg ?
	In .\nonlocalized\chrome
		uncomp brower.jar
	In .\nonlocalized\defaults\pref\firefox.ini
		pref("browser.shell.checkDefaultBrowser", true); => false
		pref("profile.allow_automigration", false); => true
		pref("browser.sessionstore.resume_from_crash", true); => false
	In .\nonlocalized\applications.ini
		[XRE]
			EnableProfileMigrator=1		=> 0 (Discard Migration account) DISFUNCT from FF11.0 !!
		[Crash Reporter]
			Enabled=1					=> 0 (Discard Crash Report)
	If file adds, don't forget to modify remove.log or precomplete

	If v16.0.2, uncomp omni.ja (jar file)
		in core/omni.ja(?)extensions/{...}/install.rdf ???

FF v16, file blocklist.xml seems cool :
    <pluginItem  blockID="p138">
        <match name="filename" exp="JavaAppletPlugin\.plugin" />
        <versionRange  minVersion="Java 7 Update 01" maxVersion="Java 7 Update 06" severity="1"></versionRange>
    </pluginItem>
And a bunch of mail addr

Lib sqlite3
#ce

; RepackFF submodule
; Careful : Must take care of the version
#cs
	1. uncomp FF vX in a temp dir:
			7za x -w {$strTempPath} "Firefox Setup 2.0.0.5.exe"
	2. Add/Modify/Suppress in temp dir:
			Remind to modify removed-files.log ou precomplete for uninstall
	3. Comp temp dir
			7z a -r -t7z app.7z -mx -m0=BCJ2 -m1=LZMA:d24 -m2=LZMA:d19 -m3=LZMA:d19 -mb0:1 -mb0s1:2 -mb0s2:3
	4. Create "app.tag" file including:
			;!@Install@!UTF-8!
			Title="Our New Name"
			RunProgram="setup.exe"
			;!@InstallEnd@!
	5. Concat app.tag + 7zSFX + file.7z
			copy /B 7z.sfx+app.tag+app.7z our_new_installer.exe
	6. clean up temp dir and temp files
#ce

#include <Array.au3>
#include <CommonEX.au3>

#EndRegion Header

#Region Initialization

#EndRegion Initialization

#Region Global Variables and Constants
Global $s7zPath, $s7zSFX

#EndRegion Global Variables and Constants

#Region Local Variables and Constants

#EndRegion Local Variables and Constants






#Region Public Functions
; #FUNCTION# ====================================================================================================================
; Name...........: _CheckPrerequisite
; Description....: Check file and capabilities
; Syntax.........: _CheckPrerequisite($asPrereq)
; Parameters.....: $asPrereq    - Array containing absolute path of needed file
; Return values..: Success - 0
;                  Failure - 1 and sets the @error flag to non-zero.
; Author.........: onemoretime
; Modified.......:
; Remarks........: None
; Related........:
; Link...........:
; Todo...........:
; Example........: No
; ===============================================================================================================================
Func _CheckPrerequisite($asPrereq)
	Local $iCpteur
	Local $iResult = 0
	For $iCpteur = 1 To (UBound($asPrereq) - 1)
		If Not (FileExists($asPrereq[$iCpteur])) Then
			$iResult += 1
		EndIf
	Next
	Return $iResult
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _CleanUpWorkingDir
; Description....: Cleanup a directory
; Syntax.........: _CleanUpWorkingDir($sDirToRemove)
; Parameters.....: $sDirToRemove    - Directory to cleanup
; Return values..: Success - 0
;                  Failure - 1 and sets the @error flag to non-zero.
; Author.........: onemoretime
; Modified.......:
; Remarks........: None
; Related........:
; Link...........:
; Todo...........: add preventive check (do not remove c:\ for example...)
; Example........: No
; ===============================================================================================================================
Func _CleanUpWorkingDir($sDirToRemove)
	If FileExists($sDirToRemove) Then
		If Not (DirRemove($sDirToRemove,1)) Then
			_Common_RaiseError("Warning","Unable To cleanup " & $sDirToRemove)
			return 1
		Else
			Return 0
		EndIf
	Else
		_Common_RaiseError("Warning","Nothing to remove")
		Return 1
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _Uncompress
; Description....: Uncompress an App
; Syntax.........: _Uncompress($sFileName,$sDirTarget)
; Parameters.....: $sFileName     - app to uncompress
;				   $sDirTarget	- Directory to uncompress to
; Return values..: Success - 0
;                  Failure - is fatal
; Author.........: onemoretime
; Modified.......:
; Remarks........: None
; Related........:
; Link...........:
; Todo...........: add preventive check (do not remove c:\ for example...)
; Example........: No
; ===============================================================================================================================
Func _Uncompress($sFileName,$sDirTarget)
	Local $iResult
	Local $s7zParam = " x -w:" & $sDirTarget & "\ " & chr(34) & $sFileName & chr(34)
	$iResult = RunWait(@ComSpec & " /c " & $s7zPath & " " & $s7zParam,$sDirTarget,@SW_HIDE)
	If ($iResult = 0) Then
		Return 0
	Else
		_Common_RaiseError("Fatal","Error while uncompress " & $sFileName & " in " & $sDirTarget)
	EndIf
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _Compress
; Description....: Compress an App
; Syntax.........: _Compress($sDirToCompress,$sDirTarget,$sFileName, $sAppName)
; Parameters.....: $sDirToCompress  - Directory to compress
;				   $sDirTarget		- Directory to compress into
;				   $sFileName		- Target Name without extension
;				   $sAppName		- Name of the app
; Return values..: Success - 0
;                  Failure - 1 and sets the @error flag to non-zero.
; Author.........: onemoretime
; Modified.......:
; Remarks........: None
; Related........:
; Link...........:
; Todo...........: add preventive check (do not remove c:\ for example...)
; Example........: No
; ===============================================================================================================================
Func _Compress($sDirToCompress,$sDirTarget,$sFileName, $sAppName)
	Local $iResult
	Local $sCopyConcatParam = " /B " & $s7zSFX & "+" & $sDirTarget & "\app.tag" & "+" _
		& $sDirTarget & "\Repacked_" & $sFileName & ".7z" _
		& " " & $sDirTarget & "\Repacked_" & $sFileName & ".exe"

	Local $s7zParam =" a -r -t7z " & $sDirTarget & "\Repacked_" & $sFileName & ".7z" _
		& " -mx -m0=BCJ2 -m1=LZMA:d24 -m2=LZMA:d19 -m3=LZMA:d19 -mb0:1 -mb0s1:2 -mb0s2:3" _
		& " " & $sDirToCompress & "\*"

	$iResult = RunWait(@ComSpec & " /c " & $s7zPath & " " & $s7zParam,$sDirTarget,@SW_HIDE)
	If Not ($iResult = 0) Then
		MsgBox(0,"Error","Error while compress " & $sFileName & " in " & $sDirTarget)
		return $iResult
	EndIf
	; app.tag creation (overwrites existing app.tag)
	$hAppTag = FileOpen($sDirTarget & "\app.tag",2)
	If ($hAppTag = -1) Then
		MsgBox(0, "Error", "Unable to create app.tag")
		return 1
	EndIf
	FileWriteLine($hAppTag,";!@Install@!UTF-8!")
	FileWriteLine($hAppTag,"Title=" & chr(34) & $sAppName & chr(34))
	FileWriteLine($hAppTag,"RunProgram="& chr(34) & "setup.exe"& chr(34))
	FileWriteLine($hAppTag,";!@InstallEnd@!")
	FileClose($hAppTag)
	; Concat files
	; copy /B 7zSD.sfx+app.tag+app.7z our_new_installer.exe
	$iResult = RunWait(@ComSpec & " /c " & "copy " & $sCopyConcatParam,$sDirTarget,@SW_HIDE)
	If @error Then
		MsgBox(0,"Error","Error while concat files in " & $sDirTarget)
		return $iResult
	EndIf
	; remove temp files
	;FileDelete($sDirTarget & "\app.tag")
	;FileDelete($sDirTarget & "\Repacked_" & $sFileName & ".7z")
	; all good & done
	return 0
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _Heart
; Description....: Do all the modification
; Syntax.........: _Heart($sAppVersion)
; Parameters.....: $sAppVersion    - Firefox version to repack
; Return values..: Success - 0
;                  Failure - 1 and sets the @error flag to non-zero.
; Author.........: onemoretime
; Modified.......:
; Remarks........: None
; Related........:
; Link...........:
; Todo...........:
; Example........: No
; ===============================================================================================================================
Func _Heart($sAppVersion)
	; There are a bunch of files to modify
	; the idea is to load the file, regex the modification, suppress lines and overwrite the file
	; with same flags
	;
	; Careful : actions depend of the target version...

	return 0
EndFunc
#EndRegion Public Functions

#Region Embedded DLL Functions
#EndRegion Embedded DLL Functions

#Region Internal Functions
#EndRegion Internal Functions