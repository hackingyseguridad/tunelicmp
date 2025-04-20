#!/bin/bash

# Esto requiere tcpdump y permisos root
tcpdump -i eth0 -n -s 0 -x 'icmp[0] = 8' 2>/dev/null | awk '
/ICMP echo request/ {
  # Extraer payload (últimos 32 caracteres de la línea)
  payload = substr($0, length($0)-31, 32)
  # Extraer secuencia (primeros 4 caracteres)
  seq = substr(payload, 1, 4)
  # Si es paquete de fin
  if (seq == "FFFF") exit
  # Extraer datos (resto)
  data = substr(payload, 5)
  print data
}' | xxd -r -p > archivo_recibido
