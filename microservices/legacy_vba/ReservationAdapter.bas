Option Explicit

Private Const BACKEND_URL As String = "https://your-2r-backend.example.com/api"
Private Const API_TOKEN As String = ""

Private Function GetAuthToken() As String
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Sheets("Config")
    If Not ws Is Nothing Then
        Dim tok As String
        tok = ws.Range("B1").Value
        If Len(tok) > 0 Then
            GetAuthToken = tok
            Exit Function
        End If
    End If
    GetAuthToken = API_TOKEN
End Function

Private Function HttpGet(url As String) As String
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP.6.0")
    http.Open "GET", url, False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "Authorization", "Bearer " & GetAuthToken()
    http.Send
    If http.Status = 200 Then
        HttpGet = http.responseText
    Else
        HttpGet = ""
    End If
    Set http = Nothing
End Function

Private Function HttpPost(url As String, body As String) As String
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP.6.0")
    http.Open "POST", url, False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "Authorization", "Bearer " & GetAuthToken()
    http.Send body
    HttpPost = http.responseText
    Set http = Nothing
End Function

Public Sub FetchReservationsToSheet()
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Sheets.Add
    ws.Name = "Reservations_" & Format(Now, "YYYYMMDD_HHMMSS")

    ws.Range("A1:F1").Value = Array("ID", "Room", "Title", "Start", "End", "Status")
    ws.Range("A1:F1").Font.Bold = True

    Dim raw As String
    raw = HttpGet(BACKEND_URL & "/reservations")

    If Len(raw) = 0 Then
        MsgBox "Failed to fetch reservations. Check backend URL and token.", vbExclamation
        Exit Sub
    End If

    MsgBox "Data fetched. Raw JSON preview (first 500 chars):" & vbCrLf & Left(raw, 500), vbInformation
End Sub

Public Sub CreateReservationFromSelection()
    Dim ws As Worksheet
    Set ws = ActiveSheet

    Dim roomId As String
    Dim title As String
    Dim startTime As String
    Dim endTime As String

    roomId    = InputBox("Room ID (e.g. CONF-A1):")
    title     = InputBox("Meeting Title:")
    startTime = InputBox("Start Time (YYYY-MM-DDTHH:MM:SS):")
    endTime   = InputBox("End Time (YYYY-MM-DDTHH:MM:SS):")

    If Len(roomId) = 0 Or Len(startTime) = 0 Or Len(endTime) = 0 Then
        MsgBox "All fields are required.", vbExclamation
        Exit Sub
    End If

    Dim payload As String
    payload = "{""room_id"":""" & roomId & """," & _
              """title"":"""    & title & """," & _
              """start_time"":""" & startTime & """," & _
              """end_time"":"""   & endTime & """}"

    Dim response As String
    response = HttpPost(BACKEND_URL & "/reservations", payload)

    If Len(response) > 0 Then
        MsgBox "Reservation created successfully." & vbCrLf & Left(response, 300), vbInformation
    Else
        MsgBox "Request failed. Check your connection and credentials.", vbCritical
    End If
End Sub

Public Sub SyncReservationsFromSheet()
    Dim ws As Worksheet
    Set ws = ActiveSheet

    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row

    Dim i As Long
    Dim synced As Long
    synced = 0

    For i = 2 To lastRow
        Dim roomId As String
        Dim title As String
        Dim startTime As String
        Dim endTime As String
        Dim syncStatus As String

        roomId    = CStr(ws.Cells(i, 1).Value)
        title     = CStr(ws.Cells(i, 2).Value)
        startTime = Format(CDate(ws.Cells(i, 3).Value), "YYYY-MM-DDTHH:MM:SS")
        endTime   = Format(CDate(ws.Cells(i, 4).Value), "YYYY-MM-DDTHH:MM:SS")
        syncStatus = CStr(ws.Cells(i, 5).Value)

        If syncStatus = "SYNCED" Or Len(roomId) = 0 Then GoTo NextRow

        Dim payload As String
        payload = "{""room_id"":""" & roomId & """," & _
                  """title"":"""    & title & """," & _
                  """start_time"":""" & startTime & """," & _
                  """end_time"":"""   & endTime & """}"

        Dim response As String
        response = HttpPost(BACKEND_URL & "/reservations", payload)

        If InStr(response, """status"":""confirmed""") > 0 Then
            ws.Cells(i, 5).Value = "SYNCED"
            synced = synced + 1
        Else
            ws.Cells(i, 5).Value = "ERROR"
        End If

NextRow:
    Next i

    MsgBox "Sync complete. " & synced & " reservation(s) created.", vbInformation
End Sub
