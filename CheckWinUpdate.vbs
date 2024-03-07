' http://zabbix.org/wiki/Monitoring_Windows_Updates

Set args = WScript.Arguments
 
IF (WScript.Arguments.Count > 0) Then
	IF (WScript.Arguments.Item(0) = "last") Then
		Set objSession = CreateObject("Microsoft.Update.Session")
		Set objSearcher = objSession.CreateUpdateSearcher
		Set colHistory = objSearcher.QueryHistory(0,1)
 
		For Each objEntry in colHistory
			WScript.Echo  date2epoch(objEntry.Date)
		Next
 
	Else
		Wscript.Echo getUpdates(WScript.Arguments.Item(0))
	End IF	
Else
	Wscript.Echo "ERROR in CheckWinUpdate parameter"
End IF
 
 
Function getUpdates(updateType)
	Set objSearcher = CreateObject("Microsoft.Update.Searcher")
	Set objResults = objSearcher.Search("IsInstalled=0")
	Set colUpdates = objResults.Updates
 
	updatesHigh = 0
	updatesOptional = 0
	priorityUpdateList = "Priority Updates:" & vbCrLf
	optionalUpdateList = "Optional Updates:" & vbCrLf
 
	For i = 0 to colUpdates.Count - 1
		If (colUpdates.Item(i).IsInstalled = False AND colUpdates.Item(i).AutoSelectOnWebSites = False) Then
			updatesOptional = updatesOptional + 1
			title = "Optional Update"
			optionalUpdateList = optionalUpdateList & colUpdates.Item(i).Title & vbCrLf
		ElseIf (colUpdates.Item(i).IsInstalled = False AND colUpdates.Item(i).AutoSelectOnWebSites = True) Then
			updatesHigh = updatesHigh + 1
			title = "High Priority Update"
			priorityUpdateList = priorityUpdateList & colUpdates.Item(i).Title & vbCrLf
		End IF
	Next
 
	IF (updateType = "priority") Then
		getUpdates = updatesHigh
	ElseIf (updateType = "optional") Then
		getUpdates = updatesOptional
	ElseIf (updateType = "total") Then
		getUpdates = (updatesHigh + updatesOptional)
	ElseIf (updateType = "full") Then
		getUpdates = priorityUpdateList & vbCrLf & optionalUpdateList
	Else
		getUpdates = "ERROR in CheckWinUpdate parameter"
	End IF
End function
 
Function getmydat(wmitime) 
  dtmInstallDate.Value = wmitime 
  getmydat = dtmInstallDate.GetVarDate
End function
 
 
function date2epoch(myDate)
date2epoch = DateDiff("s", "01/01/1970 00:00:00", myDate)
end function