#!/bin/bash
set -e

echo "[*] Mounting configfs…"
if ! mountpoint -q /sys/kernel/config; then
  sudo mount -t configfs configfs /sys/kernel/config
fi

ORIG_DIR=$(pwd)
G=/sys/kernel/config/usb_gadget/magstripe_gadget
echo "[*] Cleaning up any old gadget…"
[ -d "$G" ] && sudo rm -rf "$G"

echo "[*] Creating gadget at $G"
sudo mkdir -p "$G"
cd "$G"

echo "[*] Writing device IDs…"
echo 0x1d6b | sudo tee idVendor      >/dev/null
echo 0x0104 | sudo tee idProduct     >/dev/null
echo 0x0100 | sudo tee bcdDevice     >/dev/null
echo 0x0200 | sudo tee bcdUSB        >/dev/null

echo "[*] Writing English strings…"
sudo mkdir -p strings/0x409
echo "0123456789"               | sudo tee strings/0x409/serialnumber >/dev/null
echo "Xerox"                    | sudo tee strings/0x409/manufacturer >/dev/null
echo "Virtual Magstripe Reader" | sudo tee strings/0x409/product      >/dev/null

echo "[*] Configuring HID function…"
sudo mkdir -p functions/hid.usb0
echo 1 | sudo tee functions/hid.usb0/protocol      >/dev/null
echo 1 | sudo tee functions/hid.usb0/subclass      >/dev/null
echo 27| sudo tee functions/hid.usb0/report_length >/dev/null
# 27-byte report descriptor (vendor/Fake HID)
printf '\x06\x00\xFF\x09\x01\xA1\x01\x15\x00\x26\xFF\x00\x75\x08\x95\x40\x09\x01\x81\x02\x09\x01\x91\x02\xC0' \
  | sudo tee functions/hid.usb0/report_desc >/dev/null

echo "[*] Creating configuration…"
sudo mkdir -p configs/c.1/strings/0x409
echo "Config 1: HID" | sudo tee configs/c.1/strings/0x409/configuration >/dev/null
echo 120           | sudo tee configs/c.1/MaxPower               >/dev/null

echo "[*] Binding HID function into configuration…"
sudo ln -s functions/hid.usb0 configs/c.1/

echo "[*] Enabling gadget (binding to UDC)…"
UDC=$(ls /sys/class/udc | head -n1)
if [ -z "$UDC" ]; then
  echo "ERROR: no UDC found; cannot enable gadget" >&2
  exit 1
fi
echo "$UDC" | sudo tee UDC >/dev/null

echo "[*] Gadget is live. Now running uhid swipe…"

cd "$ORIG_DIR"
echo "[*] Building uhid from Makefile…"
make

if [ ! -f ./uhid ]; then
  echo "ERROR: uhid binary not found after make" >&2
  exit 1
fi

chmod 666 /dev/uhid

echo "[*] Running uhid…"
sudo ./uhid

echo "[*] All done."
