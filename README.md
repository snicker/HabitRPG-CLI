HabitRPG-CLI
============
HabitRPG-CLI is a command-line-based tool written in the [AutoIT][2] scripting language for communicating with the [HabitRPG][1] v1 [API][1a] to either "up" or "down" a habit and provide feedback to the user.

HabitRPG-CLI integrates with [Growl for Windows][3] to send a notification upon communication with the HabitRPG server. The notification shows the change in XP and GP and can also show a custom message.

[1]: https://habitrpg.com (HabitRPG)
[1a]: https://github.com/lefnire/habitrpg/wiki/API (HabitRPG v1 API)
[2]: http://www.autoitscript.com/site/ (AutoIT)
[3]: http://www.growlforwindows.com/ (Growl for Windows)

Usage
-----
HabitRPG-CLI accepts 3 parameters, 2 required and 1 optional:

`habitrpg <taskID/taskName> <direction:up|down> <message (optional)>`

The `taskID/taskName` should correspond to a Habit on the HabitRPG site, or can be a new habit (the API will automatically create it on the first call).

`direction` needs to either be "up" or "down" depending on whether you want a bonus or a demerit.

The `message` parameter is optional and will be shown instead of the default message in the [Growl][3] notification.

### Examples

To give yourself a bonus for the "Productivity" habit and send a custom message:

`habitrpg Productivity up "Great job, awesome productivity bonus awarded!"`

If you're indulging your bad browsing habits:

`habitrpg Browsing down`

Configuration
-------------
You will need to edit the "habitrpg.ini" file in the same folder as HabitRPG-CLI to add your User ID and API Key for HabitRPG. This can be found in the settings area of your account on the [HabitRPG][1] site.

	[HabitRPGSettings]
	UID=<your user id goes here>
	APIKey=<your api key goes here>
	
Why?
----
Why not? Also, I wanted to have give myself a habit bonus for checking off tasks in Outlook. Writing an Outlook plug-in seemed a little too one-track-minded to me, so I wrote a small VBA hook to watch for completed tasks and execute this application to communicate with HabitRPG. I've since used it for other similar unnecessarily complicated situtations.

If you want to do the same horrendous thing, hit `Alt-F11` in Outlook, paste this snippet into "ThisOutlookSession":

	Dim WithEvents colItems As outlook.Items

	Private Sub Application_Startup()
		Call register_itemchange_handler
	End Sub

	Private Sub register_itemchange_handler()
		Set colItems = Application.GetNamespace("MAPI").GetDefaultFolder(olFolderTasks).Items
	End Sub

	Private Sub colItems_ItemChange(ByVal Item As Object)
		If Item.Complete Then
			Dim habitrpgprop As UserProperty
			Set habitrpgprop = Item.UserProperties.Find("habitrpgcomplete", True)
			If habitrpgprop Is Nothing Then
				Set habitrpgprop = Item.UserProperties.Add("habitrpgcomplete", olYesNo)
				habitrpgprop.Value = True
				Item.Save
				HabitRPGProductivityUp ("Completed Outlook Task '" & Item.Subject & "'")
			End If
		End If
	End Sub
	
	Public Sub HabitRPGProductivityUp(Reason As String)
		Shell ("C:\Path\To\HabitRPG-CLI\HabitRPG.exe todo up " & Chr(34) & Reason & Chr(34))
	End Sub
	
...and adjust the path in the HabitRPGProductivityUp subroutine to point to your installation.
	
Credits
-------
This application uses several libraries written by others for AutoIT:

* [JSON UDF Library][4] 0.9.1 by Gabriel Boehme
* [Growl for Windows UDF][6] by [Markus Mohnen][8]

	I recommend his [Gmail Growl][9] tool if you use Gmail and Growl for Windows, it is the reason this UDF exists.
* [Asynchronous Sockets UDF][5] by Kostas (Required by Growl UDF)
* [WinHttp][7] 1.6.2.5 by trancexx and ProgAndy

[4]: http://www.autoitscript.com/forum/topic/104150-json-udf-library-fully-rfc4627-compliant/ (JSON UDF Library)
[5]: http://www.autoitscript.com/forum/index.php?showtopic=45189 (Async Sockets UDF)
[6]: http://www.autoitscript.com/forum/topic/95141-growl-for-windows-udf/ (Growl for Windows UDF)
[7]: https://code.google.com/p/autoit-winhttp/ (WinHTTP wrapper for AutoIt)
[8]: http://markus.mohnen.net/ (Markus Mohnen)
[9]: http://gmailgrowl.blogspot.com/ (Gmail Growl)