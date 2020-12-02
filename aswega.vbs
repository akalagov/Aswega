'C:\Windows\SysWOW64\cscript.exe //NoLogo  F:\Software\Aswega\aswega.vbs

'Вывод на консоль в виде "Q1;Q2;T1;T2;T3;dT;P;E;V1;V2;Время;Дата;Tраб;p1;p2"
'То есть "3.215;3.192;54.12;42.34;0.0000;11.78;43.91;612.9;58166.0;57712.8;23:45:21;20/11/2017;18940.9;0.0002;0.0002"

'WScript.Echo "3.215;3.192;54.12;42.34;0.0000;11.78;43.91;612.9;58166.0;57712.8;23:45:21;20/11/2017;18940.9;0.0002;0.0002"
REM VBScript Example of using MSComm control for send and receive

REM ---------------------------------------------------------------------------

' NOTES:
' This is a complete example of using the MSComm control distributed with Visual
' Studio 6 to both send and receive data. Both binary and printable text characters
' can be received. The number of characters to receive before ending the script is
' settable through 'threshold'.

' For maximum efficiency of burst-mode data, the event handler buffers the
' incoming data before writing it to the file. Since it is not possible to
' know how many characters may be in the MSComm control's input buffer, the
' only sure way of knowing how many characters are received is to accumulate
' the count through a call to the control's InBufferCount property. While this
' may appear to be counter-intuitive, the control does not interrupt the program
' on every received character. It is not possible to know how many characters
' are waiting without using the InBufferCount property. When the Input()
' method is called, it will take InBufferCount number of bytes (all of them) out
' of the input buffer if the InputLen property is set to '0'.

' After the threshold number of bytes are received, the event handler processes
' the contents of the receive buffer by writing the contents to the log file
' two bytes at a time with commas separating each pair of bytes.

Option Explicit

Dim objComm                             ' MSComm control reference pointer
Dim s                                   ' general purpose string
Dim s1                                   ' general purpose string
Dim s2                                   ' general purpose string
Dim txBuf                                 ' message sent out of comm port
Dim threshold                   		' how many characters to receive until done
Dim flag                                ' indicates whether or not script continues
Dim rxCnt
Dim rxBuf
Dim outBuf
Dim i

const MyPort = 5						' COM1
const MyBaud = "4800"					' bps rate

const comEvSend = 1						' enumeration of comm events
const comEvReceive = 2
const comEvCTS = 3
const comEvDSR = 4
const comEvCD = 5
const comEvRing = 6
const comEvEOF = 7

const comInputModeText = 0              ' enumeration of input mode constants
const comInputModeBinary = 1

const heatMeterNumber = 19855			' Номер счетчика

outBuf = "Стоп"
rxCnt = 0

Set objComm = WScript.CreateObject _
("MSCOMMLib.MSComm.1", "MSCommEvent_")  ' second parameter (MSCommEvent_) +
                                        ' name of event (OnComm) creates the
                                        ' event handler that is called when
                                        ' the event fires


objComm.CommPort = MyPort               ' select a port to use
objComm.InputLen = 0                    ' if = 0, will retrieve all waiting chars
objComm.InputMode = comInputModeText	' causes Input() to return string (not array)
'objComm.InputMode = comInputModeBinary	' causes Input() to return array (not string)
objComm.RThreshold = 1                  ' must be non-zero to enable receive
objComm.PortOpen = TRUE                 ' open COM port for use

s = MyBaud & ",e,8,1"                   ' settings: baud,parity,bits,stop in BSTR
objComm.Settings = s                    ' send to COM port

threshold = 1							' В ответ на последующий запрос ожидаем 1 байт

' Перевод счетчика в активное состояние
txBuf = Chr(((heatMeterNumber And (Not 16383)) / 16384) Or 192)
txBuf = txBuf & Chr((heatMeterNumber And (Not 1032319)) / 128)
txBuf = txBuf & Chr(heatMeterNumber And (Not 1048448))
objComm.Output = txBuf
flag = FALSE
waitingFromPort()
If Asc(rxBuf) And 16 Then
	outBuf = "Счет"
End If

threshold = 4							' В ответ на последующие запросы ожидаем 4 байта

For s = 128 To 137 Step 1
' Получаем Q1,Q2,T1,T2,T3,dT,P,E,V1,V2
rxBuf = ""
txBuf = Chr(s)
objComm.Output = txBuf
flag = FALSE
waitingFromPort()
outBuf = outBuf & ";" & Replace(LongToFloat(FourBytesToLong(Asc(Mid(rxBuf, 1, 1)), Asc(Mid(rxBuf, 2, 1)), Asc(Mid(rxBuf, 3, 1)), Asc(Mid(rxBuf, 4, 1)))), ",", ".")
Next

' Получаем Дату
rxBuf = ""
txBuf = Chr(139)
objComm.Output = txBuf
flag = FALSE
waitingFromPort()

if Hex(Asc(Mid(rxBuf, 3, 1))) < 10 Then
	s1 = "0" & Hex(Asc(Mid(rxBuf, 3, 1)))
Else
	s1 = Hex(Asc(Mid(rxBuf, 3, 1)))
End If

if Hex(Asc(Mid(rxBuf, 2, 1))) < 10 Then
	s2 = "0" & Hex(Asc(Mid(rxBuf, 2, 1)))
Else
	s2 = Hex(Asc(Mid(rxBuf, 2, 1)))
End If

outBuf = outBuf & ";" & "20" & Hex(Asc(Mid(rxBuf, 4, 1))) & "-" & s1 & "-" & s2

' Получаем Время
rxBuf = ""
txBuf = Chr(138)
objComm.Output = txBuf
flag = FALSE
waitingFromPort()
if Hex(Asc(Mid(rxBuf, 2, 1))) < 10 Then
	s = "0" & Hex(Asc(Mid(rxBuf, 2, 1)))
Else
	s = Hex(Asc(Mid(rxBuf, 2, 1)))
End If

if Hex(Asc(Mid(rxBuf, 3, 1))) < 10 Then
	s1 = "0" & Hex(Asc(Mid(rxBuf, 3, 1)))
Else
	s1 = Hex(Asc(Mid(rxBuf, 3, 1)))
End If

if Hex(Asc(Mid(rxBuf, 4, 1))) < 10 Then
	s2 = "0" & Hex(Asc(Mid(rxBuf, 4, 1)))
Else
	s2 = Hex(Asc(Mid(rxBuf, 4, 1)))
End If

outBuf = outBuf & " " & s & ":" & s1 & ":" & s2 & ".000"

' Получаем Tраб
rxBuf = ""
txBuf = Chr(140)
objComm.Output = txBuf
flag = FALSE
waitingFromPort()
outBuf = outBuf & ";" & Replace(LongToFloat(FourBytesToLong(Asc(Mid(rxBuf, 1, 1)), Asc(Mid(rxBuf, 2, 1)), Asc(Mid(rxBuf, 3, 1)), Asc(Mid(rxBuf, 4, 1)))), ",", ".")

For s = 142 To 143 Step 1
' Получаем p1,p2
rxBuf = ""
txBuf = Chr(s)
objComm.Output = txBuf
flag = FALSE
waitingFromPort()
outBuf = outBuf & ";" & Replace(LongToFloat(FourBytesToLong(Asc(Mid(rxBuf, 1, 1)), Asc(Mid(rxBuf, 2, 1)), Asc(Mid(rxBuf, 3, 1)), Asc(Mid(rxBuf, 4, 1)))), ",", ".")
Next


' Перевод счетчика в пассивное состояние
txBuf = Chr(255)							
objComm.Output = txBuf					' Отправляем сообщение в порт
Wscript.Sleep (100)
objComm.PortOpen = FALSE                ' Закрываем порт
Wscript.DisconnectObject objComm        ' Удаляем объект
Set objComm = Nothing                   ' uninitialize reference pointer

Wscript.Echo outBuf						' Вывод результата на консоль

REM ---------------------------------------------------------------------------
Sub waitingFromPort
	i = 0
	While (flag = FALSE) And (i < 50)	' Вводим скрипт в режим ожидания символов с порта
		Wscript.Sleep (20)
		i = i + 1
	Wend
End Sub

REM ---------------------------------------------------------------------------
Sub MSCommEvent_OnComm					' Обработчик события OnComm
    Select Case objComm.CommEvent
        Case comEvReceive
            rxCnt = rxCnt + objComm.InBufferCount
            rxBuf = rxBuf & objComm.Input
            If rxCnt >= threshold Then
                flag = TRUE
                rxCnt = 0
            End If
        Case Else
    End Select
End Sub

'WSCript.echo LongToFloat(FourBytesToLong(&H76, &H64, &H40, &HF8)) '0,0008708333
Function FourBytesToLong(B0, B1, B2, B3)
	Dim S

	S = 0
	If B1 >= 128 Then
		S = 1
	End If

	B1 = (B1 And 127) + ((B0 And 1) * 128)
	B0 = B0 And (Not 1)
	If B0 > 0 Then
		B0 = ((B0 - 2) / 2) + S * 128
	End If

	If S = 1 Then
		FourBytesToLong = -((255 - B0) * &H1000000 + (255 - B1) * &H10000 + _
						(255 - B2) * &H100& + (255 - B3) + 1)
	Else
		FourBytesToLong = B0 * &H1000000 + B1 * &H10000 + B2 * &H100& + B3
	End If
End Function

Function LongToFloat(X)
 Dim S, E, F

 S = -(X < 0)
 E = (X And &H7F800000) \ &H800000
 F = X And &H7FFFFF
 
 If (0 < E) And (E < 255) Then
    LongToFloat = (-1) ^ S * 2 ^ (E - 127) * ((F Or &H800000) / &H800000)
 ElseIf E = 0 Then
    If F = 0 Then
       If S = 0 Then
          LongToFloat = 0 'плюс ноль
       Else
          LongToFloat = -0 'минус ноль
       End If
    Else '(E = 0) And (F <> 0)
       LongToFloat = (-1) ^ S * 2 ^ (-126) * (F / &H800000)
    End If
 Else 'E = 255
    If F = 0 Then
       If S = 0 Then
          LongToFloat = 0 'плюс бесконечность
       Else
          LongToFloat = -0 'минус бесконечность
       End If
    Else '(E = 255) And (F <> 0)
       LongToFloat = 0 'не-число - NaN - Not a Number
    End If
 End If
End Function
