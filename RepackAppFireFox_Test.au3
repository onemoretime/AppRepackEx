#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         onemoretime

 Drive the repackaging of Firefox versions
 TODO :
	Drive installation and uninstallation of various Firefox versions
	Check if the installation is done
	Try to check if there're no popups
	Check if the uninstallation is clean

 Require CommonEX UDF3 module installed in include directory of AutoIt.
 See git://github.com/onemoretime/CommonEx.git

 #ce ----------------------------------------------------------------------------

#include "RepackAppFireFox.au3"
#include <CommonEx.au3>

$sPath = @ScriptDir
$sRepoPackaged = $sPath & "\repoPackaged"
$sConfigLogFilePath = @ScriptDir & "\RecupAppFF.log"

Global $s7zPath = @ScriptDir & "\7za.exe"
Global $s7zSFX = @ScriptDir & "\7z.sfx"
Dim $asApp[1] ; Name, Path, Version, ExecName
Dim $asTemp[1]
_ArrayAdd($asTemp,"FireFox")
_ArrayAdd($asTemp,$sPath)
_ArrayAdd($asTemp,"3.6")
_ArrayAdd($asTemp,"Firefox Setup 3.6.exe")
_ArrayAdd($asApp,$asTemp)

ReDim $asTemp[1]
_ArrayAdd($asTemp,"FireFox")
_ArrayAdd($asTemp,$sPath)
_ArrayAdd($asTemp,"16.0.2")
_ArrayAdd($asTemp,"Firefox Setup 16.0.2.exe")
_ArrayAdd($asApp,$asTemp)

Dim $asFileToCheck[1]
_ArrayAdd($asFileToCheck,$s7zPath)
_ArrayAdd($asFileToCheck,$s7zSFX)


If (_CheckPrerequisite($asFileToCheck)) Then
	_Common_RaiseError("Fatal","Prerequisites unachieved")
EndIf

For $iCpteur = 1 To (UBound($asApp) - 1)
	Dim $asAppToRepack[1]
	$asAppToRepack = $asApp[$iCpteur]
	If FileExists($asAppToRepack[2] & "\" & $asAppToRepack[4]) Then
		; temp dir creation. Name format : <AppName>\Temp-<AppVersion>
		$sAppFullName = $asAppToRepack[2] & "\" & $asAppToRepack[4]
		$sTempPathApp = $sRepoPackaged & "\" & $asAppToRepack[1] & "\Temp-" & $asAppToRepack[3]
		DirCreate($sTempPathApp)

		If (_Uncompress($sAppFullName,$sTempPathApp)) Then
			_Common_RaiseError("Fatal","Uncomp failed")
		EndIf
		If (_Heart($asAppToRepack[3])) Then
			_Common_RaiseError("Fatal","Repack failed")
		EndIf

		If (_Compress($sTempPathApp,$sRepoPackaged & "\" & $asAppToRepack[1],$asAppToRepack[1] & "_" & $asAppToRepack[3],$asAppToRepack[1])) Then
			_Common_RaiseError("Critical","Comp failed")
		EndIf

;~ 		_CleanUpWorkingDir($strTempPathApp)
	Else
		ContinueLoop
	EndIf
Next
MsgBox(0,"End","End")