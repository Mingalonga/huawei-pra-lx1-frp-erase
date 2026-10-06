# Huawei PRA-LX1 — FRP Erase (Linux, 1 click)

```bash
git clone https://github.com/Mingalonga/huawei-pra-lx1-frp-erase
```


Borra la partición FRP de un Huawei PRA-LX1 (Kirin 655) via testpoint + VCOM, sin necesitar cuenta Google ni desbloquear el bootloader.

**Sistema operativo:** Linux (Ubuntu, Pop!_OS, Debian...)
**No funciona en Windows.**

---

## Setup (hacer una vez)

### 1. Dependencias

```bash
sudo apt install build-essential libusb-1.0-0-dev pkg-config android-tools-fastboot git
```

### 2. Compilar huawei-usbupdate-tool

```bash
git clone https://github.com/builder555/huawei-usbupdate-tool ~/huawei-usbupdate-tool
cd ~/huawei-usbupdate-tool && make
```

### 3. Instalar reglas udev

```bash
sudo cp 51-huawei-fastboot.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG plugdev $USER
```

### 4. Clonar este repo

```bash
git clone https://github.com/Mingalonga/huawei-pra-lx1-frp-erase
cd huawei-pra-lx1-frp-erase
cd huawei-pra-lx1-frp-erase
chmod +x frp_erase.sh
```

---

## Uso

```bash
sudo ./frp_erase.sh
```

El script te guía paso a paso. Lo único manual es el testpoint físico en la PCB.

---

## Procedimiento del testpoint

1. Con el teléfono apagado y desconectado, abre la carcasa
2. Localiza el testpoint en la PCB (punto de cobre cerca del conector USB)
3. Haz puente a masa (GND) con un cable o clip metálico
4. Manteniendo el puente, conecta el cable USB al PC
5. Cuando el script diga que detectó /dev/ttyUSB0, suelta el testpoint
6. Espera a que el script termine solo

---

## Notas

- Pantalla negra durante todo el proceso → normal
- nvme stage rechazado → normal en PRA-LX1 (eMMC)
- "frp locked" en pantalla del bootloader → texto estático, el erase ya se hizo
- fastboot reboot puede no funcionar → desconecta USB + hard reset (Power 10s)
- El bootloader NO queda desbloqueado — solo se borra FRP

---

## Por qué este método y no PotatoNV

PotatoNV en Linux nunca transiciona de VCOM a Fastboot correctamente — ModemManager interfiere. huawei_dload mantiene el dispositivo cogido via libusb de principio a fin y la transición funciona.

---

## Compatibilidad

Probado en Huawei PRA-LX1 (Honor 6X) · Kirin 655 · Pop!_OS 22.04

---

## Créditos

El binario `huawei_dload` y los loaders Kirin son parte del proyecto [huawei-usbupdate-tool](https://github.com/huawei-usbupdate-tool). Este repo solo empaqueta las herramientas necesarias para facilitar el proceso en un único script.
