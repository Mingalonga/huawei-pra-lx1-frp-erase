#!/bin/bash
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DLOAD_BIN="$SCRIPT_DIR/huawei_dload"
LOADERS_DIR="$SCRIPT_DIR/kirin_loaders"
RELEASE_URL="https://github.com/Mingalonga/huawei-pra-lx1-frp-erase/releases/download/v1.0"

BOLD="\033[1m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}  Huawei PRA-LX1 — FRP Erase Script${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""

if ! command -v fastboot &>/dev/null; then
    echo -e "${RED}ERROR: fastboot no instalado.${NC}"
    echo "  sudo apt install android-tools-fastboot"
    exit 1
fi

if [ ! -f "$DLOAD_BIN" ]; then
    echo -e "${YELLOW}Descargando huawei_dload...${NC}"
    curl -L "$RELEASE_URL/huawei_dload" -o "$DLOAD_BIN"
    chmod +x "$DLOAD_BIN"
    echo -e "${GREEN}  ✓ huawei_dload descargado${NC}"
fi

if [ ! -f "$LOADERS_DIR/KIRIN655/1_xloader.img" ]; then
    echo -e "${YELLOW}Descargando loaders Kirin 655...${NC}"
    mkdir -p "$LOADERS_DIR/KIRIN655"
    curl -L "$RELEASE_URL/1_xloader.img" -o "$LOADERS_DIR/KIRIN655/1_xloader.img"
    curl -L "$RELEASE_URL/2_fastboot.img" -o "$LOADERS_DIR/KIRIN655/2_fastboot.img"
    echo -e "${GREEN}  ✓ Loaders descargados${NC}"
fi

echo ""
echo -e "${YELLOW}[1/3] Liberando módulos del kernel...${NC}"
sudo rmmod cdc_acm option usbserial_generic 2>/dev/null
echo -e "${GREEN}  ✓ Módulos liberados${NC}"
echo ""

echo -e "${BOLD}[2/3] Conecta el teléfono con testpoint ahora:${NC}"
echo ""
echo "  1. Haz puente a masa en el testpoint de la PCB"
echo "  2. Manteniendo el puente, conecta el USB"
echo "  3. Suelta el testpoint cuando veas ttyUSB0"
echo ""
echo -e "${YELLOW}Esperando /dev/ttyUSB0...${NC}"

TIMEOUT=60
ELAPSED=0
while [ ! -e /dev/ttyUSB0 ]; do
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
    if [ $ELAPSED -ge $((TIMEOUT * 2)) ]; then
        echo -e "${RED}Timeout: /dev/ttyUSB0 no apareció en ${TIMEOUT}s${NC}"
        exit 1
    fi
done

echo -e "${GREEN}  ✓ /dev/ttyUSB0 detectado — suelta el testpoint${NC}"
echo ""

echo -e "${YELLOW}[3/3] Cargando bootloader Kirin 655...${NC}"
echo ""
sudo "$DLOAD_BIN" -k 655 "$LOADERS_DIR/KIRIN655" -P /dev/ttyUSB0
echo ""

echo -e "${YELLOW}Esperando dispositivo en fastboot...${NC}"
TIMEOUT=30
ELAPSED=0
while ! sudo fastboot devices 2>/dev/null | grep -q "fastboot"; do
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
    if [ $ELAPSED -ge $((TIMEOUT * 2)) ]; then
        echo -e "${RED}Timeout: fastboot no detectó el dispositivo en ${TIMEOUT}s${NC}"
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
else
    echo -e "${RED}ERROR al borrar FRP${NC}"
    exit 1
fi
