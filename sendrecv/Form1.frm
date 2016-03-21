VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   5415
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   8115
   LinkTopic       =   "Form1"
   ScaleHeight     =   5415
   ScaleWidth      =   8115
   StartUpPosition =   3  'Windows Default
   Begin VB.TextBox Text1 
      Height          =   5190
      Left            =   135
      MultiLine       =   -1  'True
      ScrollBars      =   3  'Both
      TabIndex        =   0
      Text            =   "Form1.frx":0000
      Top             =   90
      Width           =   7890
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'this is a test for a small syncronous socket send/recv function.
'you can call this to send raw data to another pc over the network via tcp
'and it will not return until you have the full response from the server.
'errors are handled simply, C dll is 25k compressed.
'
'this is free for any use, open source
'
'note buffer full, and recv timeout errors do not make quicksend return false
'you will receive partial data, you can double check the lastError to see if they
'hit
'
'the reason i coded this is because sometimes you want an inline data send/recv
'without having to force syncronous behavior on top of a mswinsck.ocx control.
'which I hate.
'
'this is easier, smaller (25k vrs 122k) and does not require installation (regsvr32)

Private Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long
Private Declare Function FreeLibrary Lib "kernel32" (ByVal hLibModule As Long) As Long

'int __stdcall LastError(char* buffer, int buflen){
Private Declare Function CLastError Lib "sendrecv.dll" Alias "LastError" ( _
            ByVal buffer As String, _
            ByVal bufLen As Long) As Long


'int __stdcall QuickSend(
'   char* server, int port, char* request,
'   int reqLen, char* response_buffer, int response_buflen){

Private Declare Function CQuickSend Lib "sendrecv.dll" Alias "QuickSend" ( _
            ByVal server As String, _
            ByVal port As Long, _
            ByVal request As String, _
            ByVal reqLen As Long, _
            ByVal response_buffer As String, _
            ByVal respBufLen As Long, _
            Optional ByVal msTimeout As Long = 12000 _
            ) As Long

Dim hLib As Long


Function QuickSend(server, port, msg, ByRef response, Optional maxSize As Long = 4096) As Boolean
    
    Dim buf As String
    Dim sz As Long
    Const dllName = "sendrecv.dll"
    
    If hLib = 0 Then hLib = LoadLibrary(dllName)
    If hLib = 0 Then hLib = LoadLibrary(App.Path & "\" & dllName)
    If hLib = 0 Then hLib = LoadLibrary(App.Path & "\Release\" & dllName)
    If hLib = 0 Then hLib = LoadLibrary(App.Path & "\Debug\" & dllName)
    
    If hLib = 0 Then
        response = "Could not find library " & dllName
        Exit Function
    End If
    
    buf = String(maxSize, Chr(0))
    sz = CQuickSend(server, port, msg, Len(msg), buf, Len(buf))
    
    If sz < 1 Then 'we had an error
        sz = CLastError(buf, Len(buf))
        If sz < 1 Then
            response = "Unknown error"
        Else
            response = Mid(buf, 1, sz - 1)
        End If
    Else
        response = Mid(buf, 1, sz + 1)
        QuickSend = True
    End If
    
End Function

Private Sub Form_Load()
    
    Dim buf As String
    Dim ok As Boolean
    
    Const http = "GET /tools.php HTTP/1.0" & vbCrLf & _
                "Host: sandsprite.com" & vbCrLf & _
                "User-Agent: Mozilla/5.0 (Windows NT 5.1; rv:45.0)" & vbCrLf & _
                "Accept-Encoding: none" & vbCrLf & _
                "Connection: close" & vbCrLf & _
                "" & vbCrLf & _
                "" & vbCrLf
    
    Const maxSz = 40096
    
    ok = QuickSend("sandsprite.com", 80, http, buf, maxSz)
    Me.Caption = IIf(ok, "Success!", "Failed!")
    Text1 = buf
    
    If ok Then
        If Len(buf) = maxSz Then
            Me.Caption = Me.Caption & " Buffer full"
        Else
            Me.Caption = Me.Caption & " Size: " & Len(buf)
        End If
    End If
    

End Sub

Private Sub Form_Unload(Cancel As Integer)
    'this is just for testing in the ide, so ide doesnt hang onto
    'the dll and we can recompile it without closing ide down..
    If hLib <> 0 Then FreeLibrary (hLib)
End Sub
