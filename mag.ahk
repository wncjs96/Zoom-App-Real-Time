#SingleInstance ignore
Process, Priority, , High
OnExit handle_exit
SetWorkingDir, %A_ScriptDir%

FileInstall, bg.png, %a_temp%\bg.png, overwrite
FileInstall, titlebar.png, %a_temp%\titlebar.png, overwrite

Gui, front:+AlwaysOnTop
Gui, front:-Caption
Gui, front: Margin, 0,0
Gui, front:Add, Picture, x0 y0 gUImove, %a_temp%\titlebar.png
Gui, front:Add, Picture, x0 y68, %a_temp%\bg.png

Gui, front: font, S15
Gui, front: font, cFFFFFF

Gui, front:Add, Text, x75 y83 +BackgroundTrans, INPUT SETTINGS
Gui, front:Add, Text, x75 y103 +BackgroundTrans, F9 to show/hide this widget
Gui, front:Add, Text, x75 y123 +BackgroundTrans, F10 on Active Window to initiate calibration
Gui, front:Add, Text, x75 y143 +BackgroundTrans, F11 or MouseButton4 to show/hide display
Gui, front:Add, Text, x75 y163 +BackgroundTrans, Shift+PgUp/Pgdn to resize the display
Gui, front:Add, Text, x75 y183 +BackgroundTrans, Home to lock the position of display
Gui, front:Add, Text, x75 y203 +BackgroundTrans, PgUp/PgDown to zoom in/out
Gui, front:Add, Text, x75 y223 +BackgroundTrans, Shift+Arrow to move the display
Gui, front:Add, Text, x75 y243 +BackgroundTrans, End to move the display back to the initial place
Gui, front:Add, Text, x75 y263 +BackgroundTrans, F12 to exit
Gui, front: Show, NoActivate

  follow    := 1
  ZOOMFX    := 1.189207115
  zoom      := 2
  antialias := 1
  delay     := 10

  whMax     := 400
  wh        := 200
  whMin     := 100

  wwMax     := 800
  ww        := 200
  wwMin     := 200


  mx        := 0
  my        := 0
  mxp       := mx
  myp       := my
  wwD       := 0
  whD       := 0

  ax := 0
  ay := 0

  WinGetTitle, title, A
  state := 0
  state2 := 0
  state3 := 0
  stopmove := 0

  toggle_key := MButton
 
  Gui, main: +AlwaysOnTop  +Owner -Resize -ToolWindow +E0x00000020
  Gui, main: Show, NoActivate W%ww% H%wh% X-1000 Y-1000, MagWindow ; start offscreen

  WinSet, Transparent  , 254, MagWindow
  Gui, main: -Caption
  Gui, main: +Border
; Init zoom window
return


UImove:
PostMessage, 0xA1, 2,,, A
return



$F9::
if state3=0
Gui, front: Hide
else
Gui, front: Show, NoActivate

state3:=!state3
return

$^F11::
$^XButton1::
$+F11::
$+XButton1::
$F11::
$XButton1::
runZoom:
  if (state < 1) {
  if (stopmove = 0) {
  MouseGetPos, mx, my
  }
  ;mx := 500
  ;my := 500

  ;Gui Shown

  Gui, main: Show, NoActivate 

  WinGet, PrintSourceID, id, %title%
  ;MsgBox, PrintSourceID: + %PrintSourceID%
  hdd_frame := DllCall("GetDC", UInt, PrintSourceID)

  WinGet, PrintScreenID,  id, MagWindow
  ;WinGet, PrintScreenID,  id, MagProject
  ;MsgBox, PrintScreen: + %PrintScreenID%
  hdc_frame := DllCall("GetDC", UInt, PrintScreenID)
  if(antialias != 0)
      DllCall("gdi32.dll\SetStretchBltMode", "uint", hdc_frame, "int", 4*antialias)
  }
  else {
    Gui, main: Hide
  }
  state := 1 - state
Gosub, Repaint
return

#if state=1
$PgUp::       ; zoom in
  if zoom < 4
      zoom *= %ZOOMFX%
return

$PgDn::     ; zoom out
  if zoom > %ZOOMFX%
      zoom /= %ZOOMFX%
return


; not locked
$+PgUp::    ; larger
  if(stopmove = 0) {
  wwD =  16
  whD =  16
  Gosub, Repaint
  }
return

$+PgDn::      ; smaller
  if(stopmove = 0) {
  wwD = -16
  whD = -16
  Gosub, Repaint
  }
return

$+Up::
; get curr pos
WinGetPos, cx, cy,,,MagWindow
; then move
WinMove, MagWindow, ,cx, cy-10
return
$+Down::
; get curr pos
WinGetPos, cx, cy,,,MagWindow
; then move
WinMove, MagWindow, ,cx, cy+10
return
$+Left::
; get curr pos
WinGetPos, cx, cy,,,MagWindow
; then move
WinMove, MagWindow, ,cx-10, cy
return
$+Right::
; get curr pos
WinGetPos, cx, cy,,,MagWindow
; then move
WinMove, MagWindow, ,cx+10, cy
return

$end::
if (state2 = 0){
WinMove, MagWindow, , rx, ry
} else {
winMove, MagWindow, , cx, cy
}
state2 := !state2
return

$home::
toggle_follow:
    follow := 1 - follow
    ;MsgBox, %follow%
    stopmove := 1 - stopmove
    WinGetPos,   rx, ry,,, MagWindow

return
#if

Repaint:
    CoordMode,   Mouse, Screen
    if(stopmove = 0){
    MouseGetPos, mx, my
    mx:=mx-ax
    my:=my-ay   
    }

    WinGetPos,   wx, wy, ww, wh, MagWindow

    if(wwD != 0)
    {
       ww  += wwD
       wh  += whD
       wwD = 0
       whD = 0
    }

    if(mx != mxp) OR (my !- myp)
    {
        DllCall( "gdi32.dll\StretchBlt"
                , UInt, hdc_frame
                , Int , 2                       ; nXOriginDest
                , Int , 2                       ; nYOriginDest
                , Int , ww-6                    ; nWidthDest
                , Int , wh-6                    ; nHeightDest
                , UInt, hdd_frame               ; hdcSrc
                , Int , mx - (ww / 2 / zoom)    ; nXOriginSrc
                , Int , my - (wh / 2 / zoom)    ; nYOriginSrc
                , Int , ww / zoom               ; nWidthSrc
                , Int , wh / zoom               ; nHeightSrc
                , UInt, 0xCC0020)               ; dwRop (raster operation)

       if(follow == 1)
           WinMove, MagWindow, ,mx+ax-ww/2, my+ay-wh/2, %ww%, %wh%

        mxp = mx
        myp = my
    }

    SetTimer, Repaint , %delay%
return

; GetTitle of active window
$F10::
GetTitle:
WinGetTitle, title, A

WinGet, PrintSourceID, id, %title%

WinGetPos, ax,ay,aw,ah,%title%

hdd_frame := DllCall("GetDC", UInt, PrintSourceID)
return


; GuiClose handle_exit
$F12::
GuiClose:
handle_exit:
   DllCall("gdi32.dll\DeleteDC"    , UInt,hdc_frame )
   DllCall("gdi32.dll\DeleteDC"    , UInt,hdd_frame )
FileDelete, %a_temp%\bg.png
FileDelete, %a_temp%\titlebar.png

Process, Priority, , Normal
ExitApp

