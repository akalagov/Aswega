#!/srv/homeassistant/bin/python3.8

import serial, time, sys, io, struct, json

#initialization and open the port

#possible timeout values:
#    1. None: wait forever, block call
#    2. 0: non-blocking mode, return immediately
#    3. x, x is bigger than 0, float allowed, timeout block call

ser = serial.Serial()
ser.port = "/dev/vsps0"
ser.baudrate = 4800
ser.bytesize = serial.EIGHTBITS #number of bits per bytes
ser.parity = serial.PARITY_EVEN #set parity check
ser.stopbits = serial.STOPBITS_ONE #number of stop bits
ser.timeout = 2              #timeout block read
ser.xonxoff = False     #disable software flow control
ser.rtscts = False     #disable hardware (RTS/CTS) flow control
ser.dsrdtr = False       #disable hardware (DSR/DTR) flow control
ser.write_timeout = 2     #timeout for write
#ser.setDTR(False)

number = 19855

try:
    ser.open()
except Exception as e:
    print("error open serial port: " + str(e))
    exit()

#time.sleep(0.2)  #give the serial port sometime to receive the data

def FourBytesToFloat(var):
    b3 = var[3]
    b2 = var[2]
    b1 = (var[1] & 127) + ((var[0] & 1) << 7)
    if ((var[0] >> 1) > 0):
        b0 = ((var[0] - 2) >> 1) + (var[1] & 128)
    else:
        b0 = 0
#    print("function: %x %x %x %x" % (b0, b1, b2, b3))
#    print("asdasd: " + str(struct.unpack('>f', bytes([b0, b1, b2, b3]))[0]))

    return struct.unpack('>f', bytes([b0, b1, b2, b3]))[0]



if ser.isOpen():

    try:
        ser.flushInput() #flush input buffer, discarding all its contents
        ser.flushOutput()#flush output buffer, aborting current output
                         #and discard all that is in buffer
#        time.sleep(0.2)  #give the serial port sometime to receive the data

        # Выбор устройства
        tx = bytes([(number >> 14) | 192])
        tx = tx + bytes([(number >> 7) & 63])
        tx = tx + bytes([number & 127])
#        print("write data: " + str(tx))

        for i in range(4):
          ser.write(tx)
          rx = ser.read(1)
#          print(i)
          if rx[0] == 0x1f:
            break
          else:
            if i == 4:
              ser.close()
              print("Error communicating...")
              exit


#        ser.flush()

#        time.sleep(0.2)  #give the serial port sometime to receive the data

#        print("read data: " + str(rx[7]))

        # Q1 - Расход теплоносителя в прямом трубопроводе
#        time.sleep(0.5)  #give the serial port sometime to receive the data
        tx = chr(128).encode('latin_1')
#        print("write data: " + str(tx))
        ser.write(tx)
        rx = ser.read(4)
#        print("read data: %x %x %x %x" % (rx[0], rx[1], rx[2], rx[3]))
        q1 = '{:.3f}'.format(FourBytesToFloat(rx) * 3600)
#        print ("Q1: %f м3/ч" % q1)

        # Q2 - Расход теплоносителя в обратном трубопроводе
        tx = chr(129).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        q2 = '{:.3f}'.format(FourBytesToFloat(rx) * 3600)
#        print ("Q2: %f м3/ч" % q2)

        # T1 - Температура теплоносителя в прямом трубопроводе
        tx = chr(130).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        t1 = '{:.1f}'.format(FourBytesToFloat(rx))
#        print ("T1: %f °C" % t1)

        # T2 - Температура теплоносителя в обратном трубопроводе
        tx = chr(131).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        t2 = '{:.1f}'.format(FourBytesToFloat(rx))
#        print ("T2: %f °C" % t2)

        # T3 - Температура теплоносителя в третьем трубопроводе
        tx = chr(132).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        t3 = '{:.1f}'.format(FourBytesToFloat(rx))
#        print ("T3: %f °C" % t3)

        # dT - Разность температур теплоносителя в прямом и обратном трубопроводах
        tx = chr(133).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        dt = '{:.1f}'.format(FourBytesToFloat(rx))
#        print ("dT: %f °C" % dt)

        # P - Потребляемая тепловая мощность
        tx = chr(134).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        p = '{:.1f}'.format(FourBytesToFloat(rx))
#        print ("P: %f кВт" % p)

        # E - Количество теплоты
        tx = chr(135).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        e = '{:.3f}'.format(FourBytesToFloat(rx) / 1.163)
#        print ("E: %f Гкал" % e)

        # V1 - Объем теплоносителя в прямом трубопроводе
        tx = chr(136).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        v1 = '{:.3f}'.format(FourBytesToFloat(rx))
#        print ("V1: %f м3" % v1)

        # V2 - Объем теплоносителя в обратном трубопроводе
        tx = chr(137).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        v2 = '{:.3f}'.format(FourBytesToFloat(rx))
#        print ("V2: %f м3" % v2)

        # Дата
        tx = chr(139).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
#        print("Дата: %x.%x.%x" % (rx[1], rx[2], rx[3]))
        datetime = ("20%02x-%02x-%02x " % (rx[3], rx[2], rx[1]))
#        print(datetime)

        # Время
        tx = chr(138).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
#        print("Время: %x:%x:%x" % (rx[1], rx[2], rx[3]))
        datetime = datetime + ("%02x:%02x:%02x" % (rx[1], rx[2], rx[3]))
#        print(datetime)

        # P1 - Давление теплоносителя в прямом трубопроводе
        tx = chr(142).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        p1 = '{:.1f}'.format(FourBytesToFloat(rx))
#        print ("P1: %f мПа" % p1)

        # P2 - Давление теплоносителя в обратном трубопроводе
        tx = chr(142).encode('latin_1')
        ser.write(tx)
        rx = ser.read(4)
        p2 = '{:.1f}'.format(FourBytesToFloat(rx))
#        print ("V2: %f мПа" % p2)

        # Отмена выбора
#        time.sleep(0.5)  #give the serial port sometime to receive the data
        tx = chr(255).encode('latin_1')
#        print("write data: " + str(tx))
        ser.close()

        if float(q1) < 0 or float(q2) < 0 or float(v1) < 0 or float(v2) < 0 or float(p1) < 0 or float(p2) < 0 or float(t1) < 0 or float(t2) < 0 or float(t3) < 0 or float(dt) < 0 or float(p) < 0 or float(e) < 0:
          print("Error communicating...")
          exit

        print(json.dumps({'V1': v1, 'V2': v2, 'Q1': q1, 'Q2': q2, 'P1': p1, 'P2': p2, 'T1': t1, 'T2': t2, 'T3': t3, 'dT': dt, 'P': p
, 'E': e, 'DateTime': datetime}, sort_keys=True, indent=4))

    except Exception as e1:
        print("error communicating...: " + str(e1))

else:
    print("cannot open serial port ")
