#!/bin/bash
# ============================================================
#  Huawei PRA-LX1 — FRP Erase (Kirin 655) — 1 click
#  Método: VCOM → huawei_dload -k 655 → fastboot erase frp
# ============================================================

DLOAD_DIR="$(dirname "$(realpath "$0")")"
BOLD="\033[1m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}  Huawei PRA-LX1 — FRP Erase Script${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""

# --- Verificar dependencias ---
if ! command -v fastboot &>/dev/null; then
    echo -e "${RED}ERROR: fastboot no instalado.${NC}"
    echo "  sudo apt install android-tools-fastboot"
    exit 1
fi

if [ ! -f "$DLOAD_DIR/huawei_dload" ]; then
    echo -e "${RED}ERROR: No se encuentra $DLOAD_DIR/huawei_dload${NC}"
    exit 1
fi

# --- Paso 1: Liberar módulos ---
echo -e "${YELLOW}[1/3] Liberando módulos del kernel...${NC}"
sudo rmmod cdc_acm option usbserial_generic 2>/dev/null
echo -e "${GREEN}  ✓ Módulos liberados${NC}"
echo ""

# --- Instrucciones para el usuario ---
echo -e "${BOLD}[2/3] Conecta el teléfono con testpoint ahora:${NC}"
echo ""
echo "  1. Haz puente a masa en el testpoint de la PCB"
echo "  2. Manteniendo el puente, conecta el USB"
echo "  3. Suelta el testpoint cuando veas ttyUSB0"
echo ""
echo -e "${YELLOW}Esperando /dev/ttyUSB0...${NC}"

# Esperar ttyUSB0
TIMEOUT=60
ELAPSED=0
while [ ! -e /dev/ttyUSB0 ]; do
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
    if [ $ELAPSED -ge $((TIMEOUT * 2)) ]; then
        echo -e "${RED}Timeout: /dev/ttyUSB0 no apareció en ${TIMEOUT}s${NC}"
        echo "Asegúrate de hacer el puente antes de conectar el USB."
        exit 1
    fi
done

echo -e "${GREEN}  ✓ /dev/ttyUSB0 detectado — puedes soltar el testpoint${NC}"
echo ""

# --- Paso 2: Cargar bootloader Kirin ---
echo -e "${YELLOW}[3/3] Cargando bootloader Kirin 655 por VCOM...${NC}"
echo ""

cd "$DLOAD_DIR" || exit 1
sudo ./huawei_dload -k 655 -P /dev/ttyUSB0

echo ""

# --- Paso 3: Esperar fastboot y borrar FRP ---
echo -e "${YELLOW}Esperando dispositivo en fastboot (18d1:d00d)...${NC}"

TIMEOUT=30
ELAPSED=0
while ! sudo fastboot devices 2>/dev/null | grep -q "fastboot"; do
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
    if [ $ELAPSED -ge $((TIMEOUT * 2)) ]; then
        echo -e "${RED}Timeout: fastboot no detectó el dispositivo en ${TIMEOUT}s${NC}"
        echo ""
        echo "Prueba manualmente: sudo fastboot devices"
        exit 1
    fi
done

echo -e "${GREEN}  ✓ Dispositivo en fastboot${NC}"
echo ""
echo -e "${YELLOW}Borrando partición FRP...${NC}"

if sudo fastboot erase frp; then
    echo ""
    echo -e "${GREEN}${BOLD}================================================${NC}"
    echo -e "${GREEN}${BOLD}  ✅ FRP BORRADO CORRECTAMENTE${NC}"
    echo -e "${GREEN}${BOLD}================================================${NC}"
    echo ""
    echo "Desconecta el USB y haz hard reset (Power 10s)."
    echo "El teléfono arrancará sin pedir cuenta Google."
else
    echo -e "${RED}ERROR al borrar FRP${NC}"
    exit 1
fi
