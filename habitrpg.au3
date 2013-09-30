#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=res\icon-128.ico
#AutoIt3Wrapper_Outfile=release\habitrpg.exe
#AutoIt3Wrapper_Res_Description=HabitRPG-CLI
#AutoIt3Wrapper_Res_Fileversion=0.1.0.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Run_After=md "%scriptdir%\release\%fileversion%"
#AutoIt3Wrapper_Run_After=move /Y "%out%" "%scriptdir%\release\%fileversion%\"
#AutoIt3Wrapper_Run_After=copy "%scriptdir%\habitrpg.ini" "%scriptdir%\release\%fileversion%\" /Y
#AutoIt3Wrapper_Run_After=xcopy "%scriptdir%\res\*" "%scriptdir%\release\%fileversion%\res\" /Y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;HabitRPG-CLI
;Version 0.1 by snicker (ngordon779@gmail.com)
;https://github.com/snicker/HabitRPG-CLI
#include ".\libs\winhttp\WinHttp.au3"
#include ".\libs\growl\_Growl.au3"
#include ".\libs\json\JSON.au3"
#include <Array.au3>

Opt("MustDeclareVars", 1)

Dim $habitRpgUID = IniRead(".\habitrpg.ini","HabitRPGSettings","UID",-1)
Dim $habitAPIToken = IniRead(".\habitrpg.ini","HabitRPGSettings","APIKey",-1)

If $habitRpgUID == -1 OR $habitAPIToken == -1 Then
	MsgBox(0,"Config Missing","Please make sure habitrpg.ini is in the current directory and has your UID and API Key.")
	Exit
EndIf

If $CmdLine[0] < 2 Then
	MsgBox(0,"Missing Parameters","You must pass two parameters to HabitRPG-CLI: habitrpg <taskID> <up|down>")
	Exit
EndIf

Dim $growlAppName = "HabitRPG-CLI"
Dim $growlNotifications[3][4] = [["habitup", "Habit Bonus", @ScriptDir & "\res\icon-48-up.png", "true"], ["habitdown", "Habit Penalty", @ScriptDir & "\res\icon-48-down.png", "true"], ["notice", "Notice",@ScriptDir & "\res\icon-128.png","true" ]]
Dim $habitRpgTask = $CmdLine[1]
Dim $habitRpgDirection = StringLower($CmdLine[2])
If $habitRpgDirection <> "up" AND $habitRpgDirection <> "down" Then
	Exit
EndIf
Dim $habitRpgNounType = "Bonus"
Dim $habitRpgReason = ""
Dim $notificationType = $growlNotifications[0][0]
If $habitRpgDirection = "down" then
	$habitRpgNounType = "Penalty"
	$notificationType = $growlNotifications[1][0]
EndIf

If $CmdLine[0] > 2 then
	$habitRpgReason = $CmdLine[3]
EndIf

Global $growlHandle = _GrowlRegister($growlAppName,$growlNotifications,@ScriptDir & "\res\icon-128.png")

Global $hOpen = _WinHttpOpen("Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.6) Gecko/20100625 Firefox/3.6.6")
Global $hConnect = _WinHttpConnect($hOpen, "habitrpg.com",  $INTERNET_DEFAULT_HTTPS_PORT)
Global $hRequest = _WinHttpOpenRequest($hConnect, "POST", "api/v1/user/task/" & $habitRPGTask & "/" & $habitRpgDirection,-1, -1, -1, $WINHTTP_FLAG_SECURE)
_WinHttpAddRequestHeaders($hRequest, "x-api-user: " & $habitRpgUID)
_WinHttpAddRequestHeaders($hRequest, "x-api-key: " & $habitAPIToken)
_WinHttpSendRequest($hRequest,Default,$habitAPIToken);
_WinHttpReceiveResponse($hRequest)

Global $sReturned
If _WinHttpQueryDataAvailable($hRequest) Then
    Do
        $sReturned &= _WinHttpReadData($hRequest)
    Until @error
		
	Dim $UnJSONdResponse = _JSONDecode($sReturned)
	If $habitRpgReason <> "" Then
		$habitRpgReason = $habitRpgReason & @LF & @LF
	EndIf
	If UBound($UnJSONdResponse) > 3 Then
		$habitRpgReason = $habitRpgReason & "XP: " & StringFormat("%.2f",$UnJSONdResponse[2][1]) & @LF & "GP: " & StringFormat("%.2f",$UnJSONdResponse[3][1])
	EndIf
	_GrowlNotify($growlHandle,$notificationType,$habitRpgTask & " " & $habitRpgNounType & "!",$habitRpgReason)
Else
	_GrowlNotify($growlHandle,"notice","Error!","Couldn't communicate with the HabitRPG server")
EndIf

_WinHttpCloseHandle($hRequest)
_WinHttpCloseHandle($hConnect)
_WinHttpCloseHandle($hOpen)
