#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
; Some AV do not like UPX compressed exe...
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         onemoretime

 Ref : http://mike.kaply.com/2012/02/14/customizing-the-firefox-installer-on-windows-2012/
 Ref : http://msiworld.blogspot.com.au/2012/01/packaging-mozilla-firefox-901.html
 Ref : http://howto.gumph.org/content/customize-firefox-installer/
 Ref : http://www.thedecoderwheel.com/?p=1329

 autoconf ? autoconfig.cfg ?

 Script Functions:
	CheckPrerequisite($arrPrereq)
	CleanUpWorkingDir($strDirToRemove)
	Uncompress($strFileName,$strDirTarget)
	Compress($strDirToCompress,$strDirTarget,$strFileName, $strAppName)
	Heart($strAppVersion)

 Heart($strAppVersion)
	The heart.
	Repack the package for an real unattended install
	Must discard:
		- bookmarks migration popup
		- default nav popup
		- crash detection
	Should modify
		- default start page

; Repack directives for FF
#cs
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
#ce
#ce ----------------------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;; FootNote ;;;;;;;;;;;;;;;;
#cs
FF v16, file blocklist.xml seems cool :
    <pluginItem  blockID="p138">
        <match name="filename" exp="JavaAppletPlugin\.plugin" />
        <versionRange  minVersion="Java 7 Update 01" maxVersion="Java 7 Update 06" severity="1"></versionRange>
    </pluginItem>
And a bunch of mail addr

Lib sqlite3
#ce

; RepackFF submodule
; Careful : Must tale care of the version
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

$strPath = @ScriptDir
$strRepoPackaged = $strPath & "\repoPackaged"

$str7zPath = @ScriptDir & "\7za.exe"
$str7zSFX = @ScriptDir & "\7z.sfx"

Dim $arrayApp[1] ; Name, Path, Version, ExecName
Dim $arrTemp[1]
_ArrayAdd($arrTemp,"FireFox")
_ArrayAdd($arrTemp,$strPath)
_ArrayAdd($arrTemp,"3.6")
_ArrayAdd($arrTemp,"Firefox Setup 3.6.exe")
_ArrayAdd($arrayApp,$arrTemp)

ReDim $arrTemp[1]
_ArrayAdd($arrTemp,"FireFox")
_ArrayAdd($arrTemp,$strPath)
_ArrayAdd($arrTemp,"16.0.2")
_ArrayAdd($arrTemp,"Firefox Setup 16.0.2.exe")
_ArrayAdd($arrayApp,$arrTemp)

Dim $arrFileToCheck[1]
_ArrayAdd($arrFileToCheck,$str7zPath)
_ArrayAdd($arrFileToCheck,$str7zSFX)

Func CheckPrerequisite($arrPrereq)
	Local $intCpteur
	Local $boolResult = True
	For $intCpteur = 1 To (UBound($arrPrereq) - 1)
		If Not (FileExists($arrPrereq[$intCpteur])) Then
			$boolResult = False
		EndIf
	Next
	Return $boolResult
EndFunc

Func CleanUpWorkingDir($strDirToRemove)
	If FileExists($strDirToRemove) Then
		If Not (DirRemove($strDirToRemove,1)) Then
			MsgBox(0,"Error", "Unable To cleanup " & $strDirToRemove)
			return 0
		Else
			Return 1
		EndIf
	Else
		MsgBox(0,"Error", "Nothing to remove")
		Return 0
	EndIf
EndFunc


Func Uncompress($strFileName,$strDirTarget)
	Local $str7zParam = " x -w:" & $strDirTarget & "\ " & chr(34) & $strFileName & chr(34)
	$result = RunWait(@ComSpec & " /c " & $str7zPath & " " & $str7zParam,$strDirTarget,@SW_HIDE)
	If ($result = 0) Then
		Return 0
	Else
		ConsoleWrite(@CRLF & $result & @CRLF)
		MsgBox(0,"Error","Error while uncompress " & $strFileName & " in " & $strDirTarget)
		return $result
	EndIf
EndFunc


; FF Repack Function
;
Func Compress($strDirToCompress,$strDirTarget,$strFileName, $strAppName)
	Local $strCopyConcatParam = " /B " & $str7zSFX & "+" & $strDirTarget & "\app.tag" & "+" _
		& $strDirTarget & "\Repacked_" & $strFileName & ".7z" _
		& " " & $strDirTarget & "\Repacked_" & $strFileName & ".exe"

	Local $str7zParam =" a -r -t7z " & $strDirTarget & "\Repacked_" & $strFileName & ".7z" _
		& " -mx -m0=BCJ2 -m1=LZMA:d24 -m2=LZMA:d19 -m3=LZMA:d19 -mb0:1 -mb0s1:2 -mb0s2:3" _
		& " " & $strDirToCompress & "\*"

	$result = RunWait(@ComSpec & " /c " & $str7zPath & " " & $str7zParam,$strDirTarget,@SW_HIDE)
	If Not ($result = 0) Then
		MsgBox(0,"Error","Error while compress " & $strFileName & " in " & $strDirTarget)
		return $result
	EndIf
	; app.tag creation
	$hAppTag = FileOpen($strDirTarget & "\app.tag",2)
	If ($hAppTag = -1) Then
		MsgBox(0, "Error", "Unable to create app.tag")
		return 1
	EndIf
	FileWriteLine($hAppTag,";!@Install@!UTF-8!")
	FileWriteLine($hAppTag,"Title=" & chr(34) & $strAppName & chr(34))
	FileWriteLine($hAppTag,"RunProgram="& chr(34) & "setup.exe"& chr(34))
	FileWriteLine($hAppTag,";!@InstallEnd@!")
	FileClose($hAppTag)
	; Concat files
	; copy /B 7zSD.sfx+app.tag+app.7z our_new_installer.exe
	$result = RunWait(@ComSpec & " /c " & "copy " & $strCopyConcatParam,$strDirTarget,@SW_HIDE)
	If Not ($result = 0) Then
		MsgBox(0,"Error","Error while concat files in " & $strDirTarget)
		return $result
	EndIf
	; all good & done
	return 0
EndFunc

Func Heart($strAppVersion)
	; There are a bunch of files to modify
	; the idea is to load the file, regex the modification, suppress lines and overwrite the file
	; with same flags
	;
	; Careful : actions depend of the target version...

	return 0
EndFunc


If Not (CheckPrerequisite($arrFileToCheck)) Then
	MsgBox(0,"Fatal","Prerequisites unachieved")
	Exit -1
EndIf

For $intCpteur = 1 To (UBound($arrayApp) - 1)
	Dim $arrAppToRepack[1]
	$arrAppToRepack = $arrayApp[$intCpteur]
	If FileExists($arrAppToRepack[2] & "\" & $arrAppToRepack[4]) Then
		; temp dir creation. Name format : <AppName>\Temp-<AppVersion>
		$strAppFullName = $arrAppToRepack[2] & "\" & $arrAppToRepack[4]
		$strTempPathApp = $strRepoPackaged & "\" & $arrAppToRepack[1] & "\Temp-" & $arrAppToRepack[3]
		DirCreate($strTempPathApp)

		If (Uncompress($strAppFullName,$strTempPathApp)) Then
			MsgBox(0,"Error","Uncomp failed")
		EndIf
		If (Traitement($arrAppToRepack[3])) Then
			MsgBox(0,"Error","Repack failed")
		EndIf

		If (Compress($strTempPathApp,$strRepoPackaged & "\" & $arrAppToRepack[1],$arrAppToRepack[1] & "_" & $arrAppToRepack[3],$arrAppToRepack[1])) Then
			MsgBox(0,"Error", "Comp failed")
		EndIf

;~ 		CleanUpWorkingDir($strTempPathApp)
	Else
		ContinueLoop
	EndIf
Next
MsgBox(0,"End","End")