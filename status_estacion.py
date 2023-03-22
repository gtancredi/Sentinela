#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
'''
Sentinela de estaciones
Proyecto Bocosur
autores: Ignacio Ramirez & Gonzalo Tancredi
primera version: Julio de 2021
ultima modificacion 
version: 05/03/2023

Para correrlo:
python status_estacion.py ID Arduino.SiNo COM.Arduino
ID - # de la estacion
Arduino.SiNo - 1 si tiene arduino para temperatura y humedad, 0 si no tiene
COM.Arduino - en caso de tener arduino, puerto donde esta instalado, por ej. COM3

Si no se sabe el puerto del arduino, se puede abrir la aplicacion de arduino y fijarse
'''
import time
import ftplib
import sys
import os
import io
import csv
import datetime
import psutil
import wmi
import serial


from astral import LocationInfo
from astral.sun import sun
from pytz import timezone


nameloc='CentralUruguay'
regionloc='Uruguay'
timezoneloc='America/Montevideo'
latitude = -33.
longitude = -56.

tz = timezone(timezoneloc)

loc = LocationInfo(name=nameloc, region=regionloc, timezone=timezoneloc,
                   latitude=latitude, longitude=longitude)

FTP_HOST = 'bolidos.fisica.edu.uy'
FTP_USER = 'estacion'
FTP_PASS = 'bOcOsUr:4225;'
FTP_DIR = '/Status'
FTP_DIR_RESUMEN = '/Status/Resumen'
FTP_DIR_VIEJO = '/Status/Viejos'
IMG_DIR = '.'  # cambiar por ruta en donde se encuentra la imagen capturada
DATA_DIR = r'C:\Users\redbo\Facultad de Ciencias\application'

def get_time_suffix():
    return time.strftime('%Y_%m_%d_%H_%M_%S')

if __name__ == '__main__':

    ID = '1'
    if len(sys.argv) > 1:
        ID = sys.argv[1]  # nro. de la estacion
        if len(sys.argv) > 2:
            Arduino = int(sys.argv[2])  # 1 si tiene arduino, 0 si no lo tiene
            if Arduino == 1:
                if len(sys.argv) > 3:
                    COM = sys.argv[3]
                else:
                    sys.exit('En caso de tener arduino, debe especificar el puerto')
        else:   
            Arduino = 0  # 1 si tiene arduino, 0 si no lo tiene

    id_estacion = 'ESTACION' + ID
    BASE_NAME = 'Station_' + ID

    log_fname = id_estacion + '_' + get_time_suffix() + '.txt'
    log_fname3 = 'status_' + id_estacion + '_' + get_time_suffix() + '.txt'
    lfname = os.path.join(DATA_DIR, BASE_NAME + '.txt')  # Nombre de status file

    # Initicializa variables viejas
    yearold = 0
    monthold = 0
    dayold = 0
    hourold = 0
    minuteold = 0
    secondold = 0
    
    # Intenta leer el ultimo Station_X.txt para sacar el valor de deltaT
    try: 
        with open(lfname, 'rt') as fstatus:
            # Lectura de status file
            rows = csv.reader(fstatus, delimiter=" ", skipinitialspace=True)
            for i, row in enumerate(rows):
                match i:
                    case 1:
                        try: 
                            deltaT = float(row[0])
                        except:
                            deltaT = 0.
                    case 2:
                        gpsFlag = int(float(row[0]))
                        
            # delta Time en formato aware
            deltaT_datetime = datetime.timedelta(seconds=deltaT)
            fstatus.close()
    except:
        # Initicializa variables por si no tienen asignacion
        deltaT = 0
        gpsFlag = 0
        deltaT_datetime = datetime.timedelta(seconds=deltaT)
    
    # accede al puerto
    if Arduino == 1:
        try:
            serialarduino = serial.Serial(COM)
        except serial.SerialException as e:
            print('No pudo acceder al puerto ' + COM + ' ; sigue sin lectura de arduino')
            Arduino = 0    # Resetea la flag para correr sin informacion de arduino

    print('Sentinela iniciado, estacion', id_estacion, 'fecha', time.asctime())
    while 1 > 0:  # loop infinito hasta que se corta con Ctrl-D
        tstamp_PC_UTC = datetime.datetime.utcnow() + deltaT_datetime  # Time stamp de PC con formato
        tstamp_PC_aware = tz.localize(datetime.datetime.now())  # Time stamp tiempo local transformado de naive en aware

        # Calculo del espacio en disco
        # Indicamos la ruta del disco.
        disk_usage = psutil.disk_usage("C:\\")
        def to_gb(bytes):
           "Convierte bytes a gigabytes."
           return bytes / 1024**3
        
        espacio_total = to_gb(disk_usage.total)
        espacio_libre = to_gb(disk_usage.free)
        espacio_usado = to_gb(disk_usage.used)
        porcentaje_espacio_usado= disk_usage.percent/100
        
        
        # Determinar si la app bolidosGUI esta corriendo
        # Initializing the wmi constructor
        wmicons = wmi.WMI()
  
        flagproc = 0
  
        # Iterating through all the running processes
        for process in wmicons.Win32_Process():
            if "bolidosGUI.exe" == process.Name:
                flagproc = 1
                break

        # Lee la salida del arduino en el puerto
        if Arduino == 1:
            try:
                msgarduino = serialarduino.readline()
            except serial.SerialException as e:
                # Si no tiene lectura, pone NaN
                msgarduino = 'Humedad: NaN        Temperatura: NaN        Heater: NaN'
            
        # Info del sun
        sunco = sun(loc.observer, date=tstamp_PC_aware, tzinfo=loc.timezone,dawn_dusk_depression=13.)

        # Envia imagenes y archivo de la ultima imagen, si la hora esta durante la noche
        if tstamp_PC_aware < sunco['dawn'] or  not(tstamp_PC_aware < sunco['dusk']):
            status = "ok"
            noche = 1
            with open(lfname, 'rt') as fstatus:
                # Lectura de status file
                rows = csv.reader(fstatus, delimiter=" ", skipinitialspace=True)
                for i, row in enumerate(rows):
                    match i:
                        case 0:
                            year = int(float(row[0]))
                            month = int(float(row[1]))
                            day = int(float(row[2]))
                            hour = int(float(row[3]))
                            minute = int(float(row[4]))
                            secondfrac = float(row[5])
                            second = int(secondfrac)
                            microsecond = int((secondfrac - float(second)) * 1000000)
                        case 1:
                            try: 
                                deltaT = float(row[0])
                            except:
                                deltaT = 0.
                        case 2:
                            gpsFlag = int(float(row[0]))
                            
                fstatus.close()


            # tstamp en formato datetime       
            tstamp_stat = datetime.datetime(year=year, month=month, day=day, hour=hour, minute=minute, second=second, microsecond=microsecond)
            # delta Time en formato aware
            deltaT_datetime = datetime.timedelta(seconds=deltaT)
            # timestamp corregido por GPS
            tstamp_stat_corr =  tstamp_stat + deltaT_datetime
                
            # Time stamp de PC corregida por GPS
            tstamp_PC_UTC = datetime.datetime.utcnow() + deltaT_datetime
            # Time stamp tiempo local transformado de naive en aware
            tstamp_aware = tz.localize(datetime.datetime.now())  

            # si el tiempo del status presente no es igual al previo, hace la transferencia via ftp
            if not (
                    year == yearold and month == monthold and day == dayold and hour == hourold and minute == minuteold and second == secondold):
                
                flagstatus = 1
                
                try:
                    # connect to host
                    ftp = ftplib.FTP(FTP_HOST)  # connect to host, default port
                    #
                    # login
                    ftp.login(user=FTP_USER, passwd=FTP_PASS)
                    #
                    # lee status file
                    with open(lfname, 'rt') as fstatus:
                        data = fstatus.readline()
                    fstatus.close()

                    # escribe data
                    txtf = io.BytesIO(f"{id_estacion} {'{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr)} {status} {data}".encode())
                    # envia status file a Viejos con nombre ESTACIONX_YYMMDD-HH:MM:SS.txt , tiempo del status corregida por GPS
                    rfname = f"{id_estacion}_{'{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr)}.txt"
                    # cambia a directorio donde hace ftp viejo
                    ftp.cwd(FTP_DIR_VIEJO)
                    ftp.storlines(f"STOR {rfname}", txtf)
                    # escribe data
                    txtf = io.BytesIO(f"{id_estacion} {'{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr)} {status} {data}".encode())
                    # envia status file a nuevo
                    rfname = f"{id_estacion}_ultima.txt"
                    # cambia a directorio donde hace ftp nuevo
                    ftp.cwd(FTP_DIR)
                    ftp.storlines(f"STOR {rfname}", txtf)
                    txtf.close()
                    #
                    # envia snapshot
                    lfnameimg = os.path.join(DATA_DIR, BASE_NAME + '.jpg')
                    # envia snapshot a Viejos con nombre ESTACIONX_YYMMDD-HH:MM:SS.jpg , tiempo del status corregida por GPS
                    rfname = f"{id_estacion}_{'{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr)}.jpg"
                    imgf = open(lfnameimg, 'rb')
                    ftp.cwd(FTP_DIR_VIEJO)
                    ftp.storbinary(f"STOR {rfname}", imgf)
                    imgf.seek(0)
                    # envia snapshot a nuevo
                    rfname = f"{id_estacion}_ultima.jpg"
                    ftp.cwd(FTP_DIR)
                    ftp.storbinary(f"STOR {rfname}", imgf)
                    imgf.close()
                    msg = 'Intento a: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' - Graba el: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr) + ': OK'
                    #
                    ftp.quit()
                # Varios except del ftp
                except ftplib.error_reply as e:
                    msg = 'Intento a: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' - Graba el: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr) + ': ERROR: respuesta inesperada de FTP'
                except ftplib.error_temp as e:
                    msg = 'Intento a: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' - Graba el: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr) + ': ERROR: error TEMPORAL de protocolo FTP'
                except ftplib.error_perm as e:
                    msg = 'Intento a: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' - Graba el: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr) + ': ERROR: error PERMANENTE de protocolo FTP'
                except ftplib.error_proto as e:
                    msg = 'Intento a: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' - Graba el: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr) + ': ERROR: error de protocolo FTP'
                    # error desde el server HTTP
                except ftplib.all_errors as e:
                    msg = 'Intento a: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' - Graba el: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr) + ': ERROR: ' + str(e)

                except KeyboardInterrupt:
                    print('Sentinela terminado manualmente,', time.asctime())
                    exit(1)
            else:
                # si el tiempo del status presente es igual al previo, avisa que repite
                flagstatus = 0
                msg = 'Intento a: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' - Pero repite el: ' + '{:%Y%m%d-%H:%M:%S}'.format(tstamp_stat_corr)

            # imprimir status actual a consola y archivo de log local
            with open(log_fname, 'a') as logf:
                print(msg)
                print(msg, file=logf)

            # ftp del log file
            try:
                # connect to host
                ftp2 = ftplib.FTP(FTP_HOST)  # connect to host, default port
                #
                # login
                ftp2.login(user=FTP_USER, passwd=FTP_PASS)
                #
                # cambia a directorio donde hace ftp
                ftp2.cwd(FTP_DIR_RESUMEN)
                logf = open(log_fname, 'rb')
                ftp2.storlines(f"STOR {log_fname}", logf)
                ftp2.quit()
            except ftplib.all_errors as e:
                print('Error enviar log file')

            # Reasigna tiempo a ultimos valores
            yearold = year
            monthold = month
            dayold = day
            hourold = hour
            minuteold = minute
            secondold = second
                
        else:
            # Si es de dia, asigna valores a los flags
            noche = 0
            flagstatus = 0
            # timestamp corregido por GPS
            tstamp_PC_UTC =  datetime.datetime.utcnow() + deltaT_datetime
        
        # Mensaje final
        # Time_stamp_PC_UTC  espacio_total  espacio_libre  espacio_usado  porcentaje_espacio_usado  App.running.SiNo  noche.SiNo  nueva.imagen.SiNo  GPS.Flag  deltaT.GPS-PC  Humedad  Temperatura  Heater
        if Arduino == 1:
            msgarduinostr = msgarduino.decode()
            msgarduinostr = msgarduinostr.strip('\n')
            msgarduinostr = msgarduinostr.strip('\r')
            msgarduinostr = msgarduinostr.strip('\t')
            msgstat = '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' ' + '{:.0f}'.format(espacio_total) + \
                ' ' + '{:.0f}'.format(espacio_libre) + ' ' + '{:.0f}'.format(espacio_usado) \
                 + ' ' + '{:2.1%}'.format(porcentaje_espacio_usado) + ' ' + format(flagproc) + ' ' + format(noche) + ' ' + format(flagstatus) \
                 + ' ' + format(gpsFlag) + ' ' + '{:.2f}'.format(deltaT) + ' ' + msgarduinostr
        else:
            msgstat = '{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC) + ' ' + '{:.0f}'.format(espacio_total) + \
                ' ' + '{:.0f}'.format(espacio_libre) + ' ' + '{:.0f}'.format(espacio_usado) \
                 + ' ' + '{:2.1%}'.format(porcentaje_espacio_usado) + ' ' + format(flagproc) + ' ' + format(noche) + ' ' + format(flagstatus) \
                 + ' ' + format(gpsFlag) + ' ' + '{:.2f}'.format(deltaT)
            
        # ftp del status info
        try:
            # connect to host
            ftp3 = ftplib.FTP(FTP_HOST)  # connect to host, default port
            #
            # login
            ftp3.login(user=FTP_USER, passwd=FTP_PASS)
            #
            # envia status file viejo
            rfname3 = f"status_{id_estacion}_{'{:%Y%m%d-%H:%M:%S}'.format(tstamp_PC_UTC)}.txt"
            # escribe datos
            txtf3 = io.BytesIO(f"{msgstat}".encode())
            # cambia a directorio donde hace ftp viejo
            ftp3.cwd(FTP_DIR_VIEJO)
            ftp3.storlines(f"STOR {rfname3}", txtf3)
            # envia status file nuevo
            rfname3 = f"status_{id_estacion}_ultima.txt"
            # escribe datos
            txtf3 = io.BytesIO(f"{msgstat}".encode())
            # cambia a directorio donde hace ftp nuevo
            ftp3.cwd(FTP_DIR)
            ftp3.storlines(f"STOR {rfname3}", txtf3)
            txtf3.close()
            msg3 = 'Graba status OK: ' + msgstat
            #
            # imprimir status actual a consola y archivo de log local
            #
            ftp3.quit()
        # Varios except del ftp
        except ftplib.error_reply as e:
            msg3 = 'Intento status: ERROR: respuesta inesperada de FTP : ' + msgstat
        except ftplib.error_temp as e:
            msg3 = 'Intento status en: ERROR: error TEMPORAL de protocolo FTP : ' + msgstat
        except ftplib.error_perm as e:
            msg3 = 'Intento status en: ERROR: error PERMANENTE de protocolo FTP : ' + msgstat
        except ftplib.error_proto as e:
            msg3 = 'Intento status en: ERROR: error de protocolo FTP : ' + msgstat
            # error desde el server HTTP
        except ftplib.all_errors as e:
            msg3 = 'Intento status en: ERROR: ' + str(e) +  ' : ' + msgstat

        # imprimir status actual a consola y archivo de log local
        with open(log_fname3, 'a') as logf3:
            print(msg3)
            print(msg3, file=logf3)

          
        time.sleep(169)  # 169 segundos, para evitar multiplos de 180. least common multiple lcm con 180 es 30420


    serialarduino.close()
