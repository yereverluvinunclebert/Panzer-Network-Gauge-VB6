VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cwOverlay"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'@IgnoreModule IntegerDataType, ModuleWithoutFolder
'---------------------------------------------------------------------------------------
' Module    : cwOverlay
' Author    : beededea
' Date      : 31/07/2023
' Purpose   : create a fully click-through Widget, which allows for all kind of
'             things to render on top of the PSD-generated Widgets created in cfAlpha
'---------------------------------------------------------------------------------------

Option Explicit

Private NetworkPercent As Long

'these Public Properties are set in the Parent (here, cfAlpha)
Public cCollOverlayImages As cCollection
Public cxPerc As Single
Public cyPerc As Single

Private WithEvents W As cWidgetBase
Attribute W.VB_VarHelpID = -1
Private WithEvents tmrSampler As cTimer
Attribute tmrSampler.VB_VarHelpID = -1
Private WithEvents tmrAnimator As cTimer
Attribute tmrAnimator.VB_VarHelpID = -1

Private oldSDeg As Double
Private newSDeg As Double
Private animationQuanta As Double
Private animationAmount As Double
Private animationDivisions As Integer
Private animationInterval As Integer
Private animateCCW As Boolean

Private SDeg As Double

Private LastMoment As Date, LastRecvBytes As Long, LastSentBytes As Long

Private mTicking As Boolean             ' property Ticking
Private mPointerAnimate As Boolean    ' property PointerAnimate
Private mLocked As Boolean              ' property Locked
Private mHidden As Boolean              ' property Hidden
Private mThisNetwork As String            ' property thisNetwork
Private mThisNetworkNo As Integer          ' property thisNetwork
Private mThisOpacity As String          ' property ThisOpacity
Private mSamplingInterval As String     ' property SamplingInterval
Private mThisFace As Integer             ' property mThisFace




'---------------------------------------------------------------------------------------
' Procedure : Class_Initialize
' Author    : olaf schmidt
' Date      : 31/07/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Private Sub Class_Initialize()
    
    On Error GoTo Class_Initialize_Error

    Set W = Cairo.WidgetBase
        W.BackColor = -1  'we don't use any BackColor here, transparent
        W.ImplementsHitTest = True 'when at False, no HitTest-Event would be triggered
                    
    Set tmrSampler = Nothing
    Set tmrSampler = New_c.Timer(100, mTicking) ' first interval is 1/10th of a second, don't change it, triggers an immediate run. Correct sampling interval read later
    
    animationDivisions = 12
    animationInterval = 40
    
    Set tmrAnimator = Nothing
    Set tmrAnimator = New_c.Timer(animationInterval, False)
    
    mThisNetwork = 0
    
    ' get the list of Networks and the count
    'Call getgblNetworkArray(NetworkArray(), NetworkCount)
    
   On Error GoTo 0
   Exit Sub

Class_Initialize_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure Class_Initialize of Class Module cwOverlay"
End Sub

'---------------------------------------------------------------------------------------
' Procedure : Widget
' Author    : olaf schmidt
' Date      : 21/09/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get Widget() As cWidgetBase
   On Error GoTo Widget_Error

    Set Widget = W

   On Error GoTo 0
   Exit Property

Widget_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure Widget of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Procedure : Widgets
' Author    : olaf schmidt
' Date      : 21/09/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get Widgets() As cWidgets
   On Error GoTo Widgets_Error

    Set Widgets = W.Widgets

   On Error GoTo 0
   Exit Property

Widgets_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure Widgets of Class Module cwOverlay"
End Property


'---------------------------------------------------------------------------------------
' Property : Ticking
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get Ticking() As Boolean
   On Error GoTo TickingGet_Error

  Ticking = mTicking

   On Error GoTo 0
   Exit Property

TickingGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property Ticking of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : Ticking
' Author    :
' Date      : 09/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let Ticking(ByVal NewValue As Boolean)
    'Dim intervalValue As Integer: intervalValue = 0
    On Error GoTo TickingLet_Error

    If mTicking <> NewValue Then mTicking = NewValue Else Exit Property
    
    If mTicking Then
'        If mPointerAnimate Then
'            'intervalValue = 100
'        Else
'            'intervalValue = 500
'        End If

        tmrSampler.Enabled = True
    Else
        tmrSampler.Enabled = False
    End If

   On Error GoTo 0
   Exit Property

TickingLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property Ticking of Class Module cwOverlay"
End Property ' the earth Ticking flag

'---------------------------------------------------------------------------------------
' Property : PointerAnimate
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get PointerAnimate() As Boolean
   On Error GoTo PointerAnimateGet_Error

    PointerAnimate = mPointerAnimate

   On Error GoTo 0
   Exit Property

PointerAnimateGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property PointerAnimate of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : PointerAnimate
' Author    :
' Date      : 09/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let PointerAnimate(ByVal NewValue As Boolean)
    Dim intervalValue As Integer: intervalValue = 0
    On Error GoTo PointerAnimateLet_Error

    If mPointerAnimate <> NewValue Then mPointerAnimate = NewValue Else Exit Property
    
   On Error GoTo 0
   Exit Property

PointerAnimateLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property PointerAnimate of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property : thisOpacity
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get thisOpacity() As String
   On Error GoTo thisOpacityGet_Error

    thisOpacity = mThisOpacity

   On Error GoTo 0
   Exit Property

thisOpacityGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisOpacity of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : thisOpacity
' Author    :
' Date      : 09/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let thisOpacity(ByVal NewValue As String)
    On Error GoTo thisOpacityLet_Error

    If mThisOpacity <> NewValue Then mThisOpacity = NewValue Else Exit Property
        
    On Error GoTo 0
    Exit Property

thisOpacityLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisOpacity of Class Module cwOverlay"
End Property


'---------------------------------------------------------------------------------------
' Property : thisNetwork
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get thisFace() As Integer
   On Error GoTo thisFaceGet_Error

    thisFace = mThisFace

   On Error GoTo 0
   Exit Property

thisFaceGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisFace of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : thisFace
' Author    :
' Date      : 09/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let thisFace(ByVal NewValue As Integer)
    On Error GoTo thisFaceLet_Error

    If mThisFace <> NewValue Then mThisFace = NewValue Else Exit Property
    
    'Call obtainNetworks
    
    On Error GoTo 0
    Exit Property

thisFaceLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisFace of Class Module cwOverlay"
End Property


'---------------------------------------------------------------------------------------
' Property : thisNetwork
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get thisNetwork() As String
   On Error GoTo thisNetworkGet_Error

    thisNetwork = mThisNetwork

   On Error GoTo 0
   Exit Property

thisNetworkGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisNetwork of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : thisNetwork
' Author    :
' Date      : 09/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let thisNetwork(ByVal NewValue As String)
    On Error GoTo thisNetworkLet_Error

    If mThisNetwork <> NewValue Then mThisNetwork = NewValue Else Exit Property
    
    'Call obtainNetworks
    
    On Error GoTo 0
    Exit Property

thisNetworkLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisNetwork of Class Module cwOverlay"
End Property


'---------------------------------------------------------------------------------------
' Property : thisNetwork
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get thisNetworkNo() As Integer
   On Error GoTo thisNetworkNoGet_Error

    thisNetworkNo = mThisNetworkNo

   On Error GoTo 0
   Exit Property

thisNetworkNoGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisNetworkNo of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : thisNetworkNo
' Author    :
' Date      : 09/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let thisNetworkNo(ByVal NewValue As Integer)
    On Error GoTo thisNetworkNoLet_Error

    If mThisNetworkNo <> NewValue Then mThisNetworkNo = NewValue Else Exit Property
            
    'given a Network number select the Network string
    If mThisNetworkNo < gblNetworkCount Then
        mThisNetwork = gblNetworkIDArray(mThisNetworkNo)
    End If
    
    'Call obtainNetworks
    
    On Error GoTo 0
    Exit Property

thisNetworkNoLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property thisNetworkNo of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property : samplingInterval
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get samplingInterval() As String
   On Error GoTo samplingIntervalGet_Error

    samplingInterval = mSamplingInterval

   On Error GoTo 0
   Exit Property

samplingIntervalGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property samplingInterval of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : samplingInterval
' Author    :
' Date      : 09/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let samplingInterval(ByVal NewValue As String)
    On Error GoTo samplingIntervalLet_Error

    If mSamplingInterval <> NewValue Then mSamplingInterval = NewValue Else Exit Property

    If tmrSampler.Interval = 100 Then Call tmrSampler_Timer ' allows first early run
    
    tmrSampler.Interval = Val(mSamplingInterval) * 1000
    If mPointerAnimate = True Then
        If tmrSampler.Interval = 1000 Then tmrSampler.Interval = 1200 ' take into account the animator
    End If
    
    On Error GoTo 0
    Exit Property

samplingIntervalLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property samplingInterval of Class Module cwOverlay"
End Property


'---------------------------------------------------------------------------------------
' Property : Locked
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get Locked() As Boolean
   On Error GoTo LockedGet_Error

   Locked = mLocked

   On Error GoTo 0
   Exit Property

LockedGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property Locked of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : Locked
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let Locked(ByVal NewValue As Boolean)
   On Error GoTo LockedLet_Error

   If mLocked <> NewValue Then mLocked = NewValue Else Exit Property

   On Error GoTo 0
   Exit Property

LockedLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property Locked of Class Module cwOverlay"
End Property

'---------------------------------------------------------------------------------------
' Property  : Hidden
' Author    : beededea
' Date      : 17/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Get Hidden() As Boolean
   On Error GoTo HiddenGet_Error

   Hidden = mHidden

   On Error GoTo 0
   Exit Property

HiddenGet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property Hidden of Class Module cwOverlay"
End Property
'---------------------------------------------------------------------------------------
' Property  : Hidden
' Author    : beededea
' Date      : 10/05/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Public Property Let Hidden(ByVal NewValue As Boolean)
   On Error GoTo HiddenLet_Error

    If mHidden <> NewValue Then mHidden = NewValue Else Exit Property
    If mHidden = True Then
        W.Visible = False
        
        W.Refresh
    Else
        W.Visible = True
        
        W.Refresh
    End If

   On Error GoTo 0
   Exit Property

HiddenLet_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in Property Hidden of Class Module cwOverlay"
End Property
'
'---------------------------------------------------------------------------------------------
' Procedure : W_HitTest
' Author    : olaf schmidt
' Date      : 01/08/2023
' Purpose   : This is run continuously for the whole widget.
'             For this Overlay-Widget alone, we make everything "fully click-through"
'---------------------------------------------------------------------------------------------
'
Private Sub W_HitTest(ByVal x As Single, ByVal y As Single, HitResultHit As Boolean) 'ensure ClickThrough-behaviour in ImagePixels which are "fully Alpha"
   On Error GoTo W_HitTest_Error

   HitResultHit = False

   On Error GoTo 0
   Exit Sub

W_HitTest_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure W_HitTest of Class Module cwOverlay"
End Sub


'---------------------------------------------------------------------------------------
' Procedure : W_Paint
' Author    : olaf schmidt
' Date      : 01/08/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Private Sub W_Paint(CC As RC6.cCairoContext, ByVal xAbs As Single, ByVal yAbs As Single, ByVal dx_Aligned As Single, ByVal dy_Aligned As Single, UserObj As Object)
    Dim i As Long: i = 0
    Dim Arr As Variant
    Dim Key As String: Key = vbNullString
    Dim Pat As cCairoPattern
    Dim txtNetworkPercent As String: txtNetworkPercent = vbNullString
    Dim txtNetworkCurrent As String: txtNetworkCurrent = vbNullString
    Dim textDrawn As Boolean:   textDrawn = False
    Dim someOpacity As Double: someOpacity = 0
    Dim cream As String: cream = vbNullString
    Dim leftmost As Integer: leftmost = 0
    Dim leftmostMax As Integer: leftmostMax = 0
    Dim leftmostCurr As Integer: leftmostCurr = 0
    
    Dim scaleString As String: scaleString = vbNullString
        
    cream = RGB(235, 217, 179) ' cannot create a constant from an RGB value
   
    On Error GoTo W_Paint_Error
    
    'set some Font- and ForeColor-Properties and draw some Text on the Widget
    W.FontName = "arial"
    W.ForeColor = cream
    W.FontSize = 18
    W.FontBold = True
    W.SelectFontSettingsInto CC
    W.Refresh
    someOpacity = (Val(mThisOpacity) / 100) * 0.75
    
    txtNetworkPercent = CStr(Int(NetworkPercent))

    For i = 0 To cCollOverlayImages.Count - 1 ' this is the ExcludedPaths collection populated in cfAlpha by duplicating collPSDNonUIElements.
      Arr = cCollOverlayImages.ItemByIndex(i)
      Key = cCollOverlayImages.KeyByIndex(i)
      
      If IsArray(Arr) Then
             CC.Save
             'derive a Pattern-Obj from each retrieved ImageList-Surface-reference
             Set Pat = Cairo.ImageList(Key).CreateSurfacePattern
                         
            ' for specific keys perform rotation actions, clock hands &c
             Select Case Key
                 
                 Case "fahrenheit"
                    
                    If mThisFace = 1 Then
                        Set Pat.Matrix = Pat.Matrix.TranslateCoords(-Arr(0), -Arr(1)) 'shift the Pattern via the original X,Y PSD-Offsets (stored in Arr(0) and Arr(1))
                        CC.Paint Arr(2), Pat 'render the Pattern
                    End If
                    
                 Case "clockface"
                    
                    If mThisFace = 0 Then
                        Set Pat.Matrix = Pat.Matrix.TranslateCoords(-Arr(0), -Arr(1))
                        CC.Paint Arr(2), Pat ' render the Pattern
                    End If
                 
                 Case "redlamptrue"
                    
                    If NetworkPercent < 80 Then
                        Set Pat.Matrix = Pat.Matrix.TranslateCoords(-Arr(0), -Arr(1)) 'shift the Pattern via the original X,Y PSD-Offsets (stored in Arr(0) and Arr(1))
                        CC.Paint Arr(2), Pat 'render the Pattern
                    End If
                      
                 Case "greenlamptrue"
                    
                    If NetworkPercent >= 80 Then
                        Set Pat.Matrix = Pat.Matrix.TranslateCoords(-Arr(0), -Arr(1)) 'shift the Pattern via the original X,Y PSD-Offsets (stored in Arr(0) and Arr(1))
                        CC.Paint Arr(2), Pat 'render the Pattern
                    End If
                    
                 Case "secondshadow", "secondhand"
                                        
                    'set some Font and ForeColor Properties and draw some Text on the Widget
                    W.FontName = "arial"
                    W.ForeColor = cream
                    W.FontSize = 16
                    W.FontBold = True
                    W.SelectFontSettingsInto CC
                    W.Refresh
                    
                    leftmostMax = 265
                    leftmostCurr = 405
                    
                     ' draw the date and day in the windows just once to retain opacity
                    CC.DrawText leftmostMax, 103, 200, 200, txtNetworkPercent, , , 2, True, , someOpacity
                    CC.DrawText leftmostCurr, 103, 200, 200, txtNetworkCurrent, , , 2, True, , someOpacity
                    textDrawn = True
                    
                    Set Pat.Matrix = Pat.Matrix.TranslateCoords(11, 246) 'shift to the "rotation-point" within the Pattern
                    CC.TranslateDrawings W.Width * cxPerc, W.Height * cyPerc 'shift to the center-point of the Overlay-Widget-area
                    
                    CC.RotateDrawingsDeg SDeg
                    CC.Paint Arr(2), Pat 'render the Pattern with the current PSD-LayerAlpha, present in Arr(2)
                 
                 Case Else 'plain output for everything else ... this includes the reflection-layers,
                     
                    Set Pat.Matrix = Pat.Matrix.TranslateCoords(-Arr(0), -Arr(1))
                    CC.Paint Arr(2), Pat 'render the Pattern
                   
             End Select
             
             CC.Restore
      End If
     Next

   On Error GoTo 0
   Exit Sub

W_Paint_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure W_Paint of Class Module cwOverlay"
End Sub
Private Sub scanNetwork(ByRef thisArray() As String, ByRef thisNetworkPercentArray() As Integer, ByRef thisNetworkCount As Integer)
    On Error Resume Next
    
    Dim objInterface As CInterface
    Dim BytesRecv As Double
    Dim BytesSent As Double
    Dim BytesTotal As Double
    Dim DS As Double
    Dim US As Double
     
    Set objInterface = m_objIpHelper.Interfaces(gblNetworkIDArray(mThisNetwork))

    'lblType = m_objIpHelper.Interfaces(cboConnectionType.ListIndex + 1).InterfaceDescription & " "

    BytesRecv = Abs(m_objIpHelper.BytesReceived)
    BytesSent = m_objIpHelper.BytesSent
    BytesTotal = BytesRecv + BytesSent
    
'    lblRecv.Caption = Format(BytesRecv / 1024, "###,###,###,###,##0 KB")
'    lblSent.Caption = Format(BytesSent / 1024, "###,###,###,###,##0 KB")
    

    DS = BytesRecv - LastRecvBytes
    US = BytesSent - LastSentBytes
    
'    If DownloadSpeedTop < DS Then
'        tmrReset.Enabled = False
'        tmrReset.Enabled = True
'        DownloadSpeedTop = DS
'    End If
'    If UploadSpeedTop < US Then
'        tmrReset.Enabled = False
'        tmrReset.Enabled = True
'        UploadSpeedTop = US
'    End If

'    DownloadSpeedAverage = (DownloadSpeedAverage + DS) / 2
'    UploadSpeedAverage = (UploadSpeedAverage + US) / 2
    
'    lblDownloadSpeedTop = "Top download speed: " & Format(DownloadSpeedTop / 1024, "###,###,###,###,#0.#0 Kb/S")
'    lblUploadSpeedTop = "Top upload speed: " & Format(UploadSpeedTop / 1024, "###,###,###,###,#0.#0 Kb/S")
'    lblDownloadSpeedAverage = "Average download speed: " & Format(DownloadSpeedAverage / 1024, "###,###,###,###,#0.#0 Kb/S")
'    lblUploadSpeedAverage = "Average upload speed: " & Format(UploadSpeedAverage / 1024, "###,###,###,###,#0.#0 Kb/S")
    
'    If DS / 1024 < 1 Then
'        lblDSpeed = Format(DS, "0 BS ")
'    Else
'        lblDSpeed = Format(DS / 1024, "0.#0 KBS ")
'    End If
'    If US / 1024 < 1 Then
'        lblUSpeed = Format(US, "0 BS ")
'    Else
'        lblUSpeed = Format(US / 1024, "0.#0 KBS ")
'    End If

    
'    LastRecvBytes = BytesRecv
'    LastSentBytes = BytesSent
'    LastMoment = Now
    
'    If m_objIpHelper.Interfaces.Count <> cboConnectionType.ListCount Then
'        Dim a As Long
'        cboConnectionType.Clear
'        For a = 1 To m_objIpHelper.Interfaces.Count
'            cboConnectionType.AddItem m_objIpHelper.Interfaces(a).InterfaceDescription & " "
'        Next
'        If Val(GetSetting(App.Title, "Setting", "Connection", 0)) + 1 <= cboConnectionType.ListCount Then
'            cboConnectionType.ListIndex = Val(GetSetting(App.Title, "Setting", "Connection", 0))
'        Else
'            cboConnectionType.ListIndex = 0
'        End If
'    End If
    
End Sub
'---------------------------------------------------------------------------------------
' Procedure : tmrAnimator_Timer
' Author    :
' Date      : 30/07/2023
' Purpose   : animate timer, once every few (40) milliseconds
'---------------------------------------------------------------------------------------
'
Private Sub tmrAnimator_Timer()
    
    On Error GoTo tmrAnimator_Timer_Error
    '
    ' move the pointer using SDeg
    '
    animationAmount = animationAmount + animationQuanta

    If animateCCW = True Then
        If SDeg > newSDeg Then
            SDeg = oldSDeg - animationAmount
        Else
            tmrAnimator.Enabled = False ' when the animation is complete then stop the animator
            animationAmount = 0
            Exit Sub
        End If
    Else
        If SDeg < newSDeg Then
            SDeg = oldSDeg + animationAmount
        Else
            tmrAnimator.Enabled = False
            animationAmount = 0
            Exit Sub
        End If
    End If

    W.Parent.Refresh

   On Error GoTo 0
   Exit Sub

tmrAnimator_Timer_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure tmrAnimator_Timer of Class Module cwOverlay"
End Sub


'---------------------------------------------------------------------------------------
' Procedure : tmrSampler_Timer
' Author    :
' Date      : 30/07/2023
' Purpose   :
'---------------------------------------------------------------------------------------
'
Private Sub tmrSampler_Timer()
    Dim degDiff As Double: degDiff = 0
    
    On Error GoTo tmrSampler_Timer_Error

    If mPointerAnimate = True Then
        If tmrAnimator.Enabled = False Then
            'tmrSampler.Enabled = False
            
            ' oldSDeg stored
            oldSDeg = SDeg
            
            ' get the list of Network and the count
            Call getgblNetworkArray(gblNetworkIDArray(), gblNetworkCount)
            
            Call scanNetwork(gblNetworkIDArray(), gblNetworkPercentArray(), gblNetworkCount)
    
            'Debug.Print (thisNetworkPercentArray(0))
        
            If mThisNetworkNo <> "9999" Then
                NetworkPercent = Network_Usage_Percent
            Else
                NetworkPercent = 0
            End If
                       
            ' calculate the new signal strength amount in degrees
            newSDeg = (NetworkPercent * 3) + 30
            
            If oldSDeg = newSDeg Then Exit Sub
            
            ' calculate the difference
            degDiff = newSDeg - oldSDeg
            
            ' if the result is negative animate CCW
            If degDiff < 0 Then
                animateCCW = True
            Else
                animateCCW = False
            End If
            
            Select Case degDiff
                Case Is <= 5
                    animationDivisions = 4
                Case Is <= 10
                    animationDivisions = 8
                Case Is > 10
                    animationDivisions = 16
                Case Is > 20
                    animationDivisions = 24
            End Select
            
            ' divide that by 24 (one second duration)
            animationQuanta = Abs(degDiff / animationDivisions)
            
            'tmrAnimator.Enabled = True
            
        End If
    Else
        Call obtainNetworks
    End If
    
    W.Parent.Refresh

    tmrSampler.Enabled = True
            
   On Error GoTo 0
   Exit Sub

tmrSampler_Timer_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure tmrSampler_Timer of Class Module cwOverlay"
End Sub




' ----------------------------------------------------------------
' Procedure Name: obtainNetworks
' Purpose:
' Procedure Kind: Sub
' Procedure Access: Private
' Author: beededea
' Date: 14/01/2024
' ----------------------------------------------------------------
Private Sub obtainNetworks()
    On Error GoTo obtainNetworks_Error
    
        ' get the list of Networks and the count
        Call getgblNetworkArray(gblNetworkIDArray(), gblNetworkCount)
        
        Debug.Print gblNetworkIDArray(0)
    
        If mThisNetworkNo <> "9999" Then
            NetworkPercent = Network_Usage_Percent
        Else
            NetworkPercent = 0
        End If
                
        SDeg = (NetworkPercent * 3) + 30
        
        W.Refresh
    
    On Error GoTo 0
    Exit Sub

obtainNetworks_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure obtainNetworks, line " & Erl & "."

End Sub

' ----------------------------------------------------------------
' Procedure Name: Network_Usage_Current
' Purpose:
' Procedure Kind: Function
' Procedure Access: Private
' Return Type: Long
' Author: https://www.tek-tips.com/userinfo.cfm?member=Hypetia
' Date: 09/01/2024
' ----------------------------------------------------------------
Private Function Network_Usage_Percent() As Long
    Dim newT As Integer
    On Error GoTo Network_Usage_Percent_Error
    
    ' newT = 10
    'newT = gblNetworkPercentArray(mThisNetworkNo)

    Network_Usage_Percent = newT
     
    On Error GoTo 0
    Exit Function

Network_Usage_Percent_Error:

    MsgBox "Error " & Err.Number & " (" & Err.Description & ") in procedure Network_Usage_Percent, line " & Erl & "."

 
End Function





