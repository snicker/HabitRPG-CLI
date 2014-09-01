#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=res\icon-128.ico
#AutoIt3Wrapper_Outfile=release\habitrpg.exe
#AutoIt3Wrapper_Res_Description=HabitRPG-CLI
#AutoIt3Wrapper_Res_Fileversion=0.1.1.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Run_After=md "%scriptdir%\release\%fileversion%"
#AutoIt3Wrapper_Run_After=move /Y "%out%" "%scriptdir%\release\%fileversion%\"
#AutoIt3Wrapper_Run_After=copy "%scriptdir%\habitrpg.ini" "%scriptdir%\release\%fileversion%\" /Y
#AutoIt3Wrapper_Run_After=copy "%scriptdir%\README.md" "%scriptdir%\release\%fileversion%\" /Y
#AutoIt3Wrapper_Run_After=xcopy "%scriptdir%\res\*" "%scriptdir%\release\%fileversion%\res\" /Y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;HabitRPG-CLI
;Version 0.2.0 by snicker (ngordon779@gmail.com)
;https://github.com/snicker/HabitRPG-CLI
#include ".\libs\winhttp\WinHttp.au3"
#include ".\libs\growl\_Growl.au3"
#include ".\libs\json\JSON.au3"
#include <Array.au3>

Opt("MustDeclareVars", 1)

Dim $habitRpgUID = IniRead(@ScriptDir & "\habitrpg.ini","HabitRPGSettings","UID",-1)
Dim $habitAPIToken = IniRead(@ScriptDir & "\habitrpg.ini","HabitRPGSettings","APIKey",-1)

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

Dim $gold_gained = 0, $xp_gained = 0, $original_gold = -1, $original_xp = -1;

Dim $userdata = HRPG_Get_Member($habitRpgUID,$habitRpgUID,$habitAPIToken)[2][1]
If $userdata <> "" Then
	$original_gold = $userdata[4][1];
	$original_xp = $userdata[3][1];
EndIf

Dim $response = HRPG_Score_Task($habitRPGTask,$habitRpgDirection,$habitRpgUID,$habitAPIToken)

If $response  <> "" Then
	If $habitRpgReason <> "" Then
		$habitRpgReason = $habitRpgReason & @LF & @LF
	EndIf
	$gold_gained = $response[12][1] - $original_gold
	$xp_gained = $response[13][1] - $original_xp
	If $original_gold > -1 Then
		$habitRpgReason = $habitRpgReason & "XP: " & StringFormat("%.2f",$xp_gained) & @LF & "GP: " & StringFormat("%.2f",$gold_gained)
	EndIf
	_GrowlNotify($growlHandle,$notificationType,$habitRpgTask & " " & $habitRpgNounType & "!",$habitRpgReason)
Else
	_GrowlNotify($growlHandle,"notice","Error!","Couldn't communicate with the HabitRPG server")
EndIf

Func HRPG_Get_Member($MemberUID, $UID, $Key)
	return HRPG_API_Call("GET","members/" & $MemberUID,$UID,$Key)
EndFunc

Func HRPG_Score_Task($Task,$Direction,$UID,$Key)
	return HRPG_API_Call("POST","user/tasks/" & $Task & "/" & $Direction,$UID,$Key)
EndFunc

Func HRPG_API_Call($Method,$Route,$UID,$Key)
	Global $hOpen = _WinHttpOpen("Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.6) Gecko/20100625 Firefox/3.6.6")
	Global $hConnect = _WinHttpConnect($hOpen, "habitrpg.com",  $INTERNET_DEFAULT_HTTPS_PORT)
	Global $hRequest = _WinHttpOpenRequest($hConnect, $Method, "api/v2/" & $Route,-1, -1, -1, $WINHTTP_FLAG_SECURE)
	_WinHttpAddRequestHeaders($hRequest, "x-api-user: " & $UID)
	_WinHttpAddRequestHeaders($hRequest, "x-api-key: " & $Key)
	_WinHttpSendRequest($hRequest,Default,$Key);
	_WinHttpReceiveResponse($hRequest)
	Dim $sReturned = ""
	Dim $UnJSONdResponse = ""
	If _WinHttpQueryDataAvailable($hRequest) Then
		Do
			$sReturned &= _WinHttpReadData($hRequest)
		Until @error
		$UnJSONdResponse = _JSONDecode($sReturned)
	EndIf
	_WinHttpCloseHandle($hRequest)
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)
	return $UnJSONdResponse
EndFunc