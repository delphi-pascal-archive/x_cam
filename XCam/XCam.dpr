//=====================================//
//  Created by XProger                 //
//  mail : XProger@list.ru             //
//  site : http://xproger.mirgames.ru  //
//=====================================//
program XCam;
// ��������� �������� �������� ������������ � �������� ������
// ����� ������������� �������������� ������������ ����������, �� �������
// ������������� "����������" ��������.
// �������� ������� - ������ �������� ����� � ��������� (��� ��������)
// ����������:
// +/-                  ��������� ����������������
// ����� ������� ����   ������� ������� ���� ��������
// ������ ������� ����  ������� ������ ����������� (�� ����� 640�480 � ����������� 24 ���)

uses
  Windows, Messages;

(********* Video for windows *********)
// ������ ����� ����������� :)
const
  AVICAPDLL   = 'AVICAP32.DLL';
  WM_CAP_START                    = WM_USER;
  WM_CAP_SET_CALLBACK_FRAME       = WM_CAP_START + 5;
  WM_CAP_DRIVER_CONNECT           = WM_CAP_START + 10;
  WM_CAP_DRIVER_DISCONNECT        = WM_CAP_START + 11;
  WM_CAP_DLG_VIDEOFORMAT          = WM_CAP_START + 41;
  WM_CAP_GET_VIDEOFORMAT          = WM_CAP_START + 44;
  WM_CAP_SET_VIDEOFORMAT          = WM_CAP_START + 45;
  WM_CAP_GET_STATUS               = WM_CAP_START + 54;
  WM_CAP_GRAB_FRAME               = WM_CAP_START + 60;
  WM_CAP_STOP                     = WM_CAP_START + 68;

function    capCreateCaptureWindowA(
    lpszWindowName      : LPCSTR;
    dwStyle             : DWORD;
    x, y                : Integer;
    nWidth, nHeight     : Integer;
    hwndParent          : HWND;
    nID                 : Integer): HWND; stdcall; external AVICAPDLL;

type
  PVIDEOHDR = ^TVIDEOHDR;
  TVIDEOHDR = record
    lpData              : PBYTE;                // pointer to locked data buffer
    dwBufferLength      : DWORD;                // Length of data buffer
    dwBytesUsed         : DWORD;                // Bytes actually used
    dwTimeCaptured      : DWORD;                // Milliseconds from start of stream
    dwUser              : DWORD;                // for client's use
    dwFlags             : DWORD;                // assorted flags (see defines)
    dwReserved          : array[0..3] of DWORD; // reserved for driver
  end;

  PCAPSTATUS                      = ^TCAPSTATUS;
  TCAPSTATUS                      = record
    uiImageWidth                : UINT    ; // Width of the image
    uiImageHeight               : UINT    ; // Height of the image
    fLiveWindow                 : BOOL    ; // Now Previewing video?
    fOverlayWindow              : BOOL    ; // Now Overlaying video?
    fScale                      : BOOL    ; // Scale image to client?
    ptScroll                    : TPOINT  ; // Scroll position
    fUsingDefaultPalette        : BOOL    ; // Using default driver palette?
    fAudioHardware              : BOOL    ; // Audio hardware present?
    fCapFileExists              : BOOL    ; // Does capture file exist?
    dwCurrentVideoFrame         : DWORD   ; // # of video frames cap'td
    dwCurrentVideoFramesDropped : DWORD   ; // # of video frames dropped
    dwCurrentWaveSamples        : DWORD   ; // # of wave samples cap'td
    dwCurrentTimeElapsedMS      : DWORD   ; // Elapsed capture duration
    hPalCurrent                 : HPALETTE; // Current palette in use
    fCapturingNow               : BOOL    ; // Capture in progress?
    dwReturn                    : DWORD   ; // Error value after any operation
    wNumVideoAllocated          : UINT    ; // Actual number of video buffers
    wNumAudioAllocated          : UINT    ; // Actual number of audio buffers
  end;
(*************************************)

var
  DC    : HDC;
  Bt    : BITMAPINFO;
  h_wnd : HWND;
  h_cam : HWND;
  buf   : array [0..640 * 480 * 3] of Byte; // �����������-������
  first : Boolean = True;
  SENS  : Byte = 10;

//== ��������������� �������
function min(x, y: Integer): Integer;
begin
  if x < y then
    Result := x
  else
    Result := y;
end;

function max(x, y: Integer): Integer;
begin
  if x > y then
    Result := x
  else
    Result := y;
end;

function IntToStr(const X: Integer): string;
begin
  Str(X, Result);
end;

//== ��������� � ��������� �����
function FrameCallback(hWnd: HWND; lpVHdr: PVIDEOHDR): DWORD; stdcall;
type
  TByteArray = array [0..1] of Byte;
  PByteArray = ^TByteArray;
var
  i, j   : Integer;
  sum    : Single;
  status : TCapStatus;
  str    : string;
begin
  Result := 0;
// ���������� � �����������
  SendMessage(h_cam, WM_CAP_GET_STATUS, SizeOf(status), Integer(@status));
// �������� �� ������������ ������� �����������
  if (status.uiImageWidth > 640) or (status.uiImageHeight > 480) or
     (lpVhdr^.dwBytesUsed div (status.uiImageWidth * status.uiImageHeight) <> 3) then
  begin
    TextOut(DC, 0,  0, '������ ����������� �� ������ ��������� 640�480 ��������', 55);
    TextOut(DC, 0,  18, '����������� ������ ���� 24 ������', 33);
    Exit;
  end;
// �������� ������
  if first then
  begin
    Move(lpVHdr^.lpData^, buf, lpVhdr^.dwBytesUsed);
    first := False;
  end;
// ���������� ��������
  for i := 0 to status.uiImageWidth * status.uiImageHeight - 1 do
  begin
    sum := 0;
    for j := 0 to 2 do
      sum := sum + abs(buf[i * 3 + j] - PbyteArray(lpVHdr^.lpData)[i * 3 + j]);
    sum := sum / 3;
    if sum > SENS then
    begin
      PbyteArray(lpVHdr^.lpData)[i * 3 + 0] := (buf[i * 3 + 0] + PbyteArray(lpVHdr^.lpData)[i * 3 + 0]) div 4;
      PbyteArray(lpVHdr^.lpData)[i * 3 + 1] := (buf[i * 3 + 1] + PbyteArray(lpVHdr^.lpData)[i * 3 + 1]) div 4;
      PbyteArray(lpVHdr^.lpData)[i * 3 + 2] := min(buf[i * 3 + 2] + PbyteArray(lpVHdr^.lpData)[i * 3 + 2], 255);
    end else
      for j := 0 to 2 do
        PbyteArray(lpVHdr^.lpData)[i * 3 + j] := buf[i * 3 + j];
  end;
// ����� ���������� � ����
  bt.bmiHeader.biWidth  := status.uiImageWidth;
  bt.bmiHeader.biHeight := status.uiImageHeight;
  StretchDIBits(DC, 0, 0, 640, 480, 0, 0, status.uiImageWidth, status.uiImageHeight, lpVHdr.lpData, bt, 0, SRCCOPY);
  TextOut(DC, 0,  0, 'LMouse - �������� ��������� ����', 32);
  TextOut(DC, 0, 16, 'RMouse - ���������', 18);
  str := '����������������: ' + IntToStr(SENS) + ' [+/-]';
  TextOut(DC, 0, 32, PChar(str), Length(str));
end;

//== ��������� Windows ��������� ����
function WndProc(hwnd: DWORD; message: UINT; wParam: Longint; lParam: LongInt): LongInt; stdcall;
begin
  case message of
  // ����� ��������� ����������
    WM_DESTROY     : PostQuitMessage(0);
  // ��������� ���������� �����
    WM_LBUTTONDOWN : first := True;
  // ����� �������� ��������
    WM_RBUTTONDOWN :
      begin
        SendMessage(h_cam, WM_CAP_DLG_VIDEOFORMAT, SizeOf(Bt), LongInt(@Bt));
        first := True;
      end;
  // ��������� ����������������, ������� +/- 
    WM_KEYDOWN :
      case wParam of
        187 : SENS := min(SENS + 1, 255); // +
        189 : SENS := max(SENS - 1, 0);   // -
      end;
  // �������� ���� �� ������� (25 ��� � �������)
    WM_TIMER       : SendMessage(h_cam, WM_CAP_GRAB_FRAME, 0, 0);
  end;
  Result := DefWindowProc(hwnd, message, wParam, lParam);
end;

const
  wnd_style = WS_POPUPWINDOW or WS_CAPTION;

var
  msg  : TMsg;
  Rect : TRect;
  wnd  : TWndClassEx;
  
begin
// �������� �������� ���� ����������
  with wnd do
  begin
    cbSize        := SizeOf(wnd);
    lpfnWndProc   := @WndProc;
    hbrBackground := COLOR_WINDOW + 1;
    hCursor       := LoadCursor (0, IDC_ARROW);
    lpszClassName := 'XCam_wnd';
  end;
  RegisterClassEx(wnd);
  h_wnd := CreateWindowEx(0, 'XCam_wnd', 'XCam video capture',
                          wnd_style, 0, 0, 0, 0, 0, 0, 0, nil);
// �������� �������� ���������� ����� ���� �� 640�480
  Rect.Left   := 0;
  Rect.Top    := 0;
  Rect.Right  := 640;
  Rect.Bottom := 480;
  AdjustWindowRect(Rect, wnd_style, False);
  MoveWindow(h_wnd, 0, 0, Rect.Right, Rect.Bottom, False);
// �������� ���������� ���� �������
  h_cam := capCreateCaptureWindowA(nil, WS_CHILD or WS_VISIBLE, 0, 0, 0, 0, h_wnd, 0);
// �������� �������������� ������������ ��������� �������� ����
  DC  := GetDC(h_wnd);
// ��������� ��������
  if SendMessage(h_cam, WM_CAP_DRIVER_CONNECT, 0, 0) <> 0 then
  begin
    SendMessage(h_cam, WM_CAP_GET_VIDEOFORMAT, SizeOf(Bt), LongInt(@Bt));
    Bt.bmiHeader.biWidth    := 320;
    Bt.bmiHeader.biHeight   := 240;
    Bt.bmiHeader.biSize     := SizeOf(Bt.bmiHeader);
    Bt.bmiHeader.biPlanes   := 1;
    Bt.bmiHeader.biBitCount := 24;
    SendMessage(h_cam, WM_CAP_SET_VIDEOFORMAT, SizeOf(Bt), LongInt(@Bt));
    SendMessage(h_cam, WM_CAP_SET_CALLBACK_FRAME, 0, Integer(@FrameCallback));
  end else
  begin
    MessageBox(h_wnd, '�� ������� ���������������� �������', nil, MB_ICONHAND);
    Exit;
  end;
  setTimer(h_wnd, 0, 40, nil); // ��������� ������� � �������� 25 ��
  ShowWindow(h_wnd, SW_SHOW);  // ���������� ������� ����. ������ ������.
// ������� ���� ��������� ���������
  while GetMessage(msg, 0, 0, 0) do
  begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
// ���������� ������ ���������
  KillTimer(h_wnd, 0);
  SendMessage(h_cam, WM_CAP_STOP, 0, 0);
  SendMessage(h_cam, WM_CAP_DRIVER_DISCONNECT, 0, 0);
end.
