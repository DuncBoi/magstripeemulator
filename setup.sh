#!/bin/bash
set -e

echo "[*] Loading kernel modules..."
sudo modprobe dwc2
sudo modprobe libcomposite

sudo mount -t configfs configfs /sys/kernel/config/ || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GADGET_DIR=/sys/kernel/config/usb_gadget/magstripe_gadget
echo "[*] Setting up USB gadget in configfs..."

# Teardown old gadget
sudo rm -rf "$GADGET_DIR"

# Create gadget
sudo mkdir -p "$GADGET_DIR"
cd "$GADGET_DIR"

# Device IDs
echo 0x1d6b | sudo tee idVendor
echo 0x0104 | sudo tee idProduct
echo 0x0100 | sudo tee bcdDevice
echo 0x0200 | sudo tee bcdUSB

# English strings
sudo mkdir -p strings/0x409
echo "0123456789"              | sudo tee strings/0x409/serialnumber
echo "Xerox"                   | sudo tee strings/0x409/manufacturer
echo "Virtual Magstripe Reader"| sudo tee strings/0x409/product

# HID function
sudo mkdir -p functions/hid.usb0
echo 1  | sudo tee functions/hid.usb0/protocol
echo 1  | sudo tee functions/hid.usb0/subclass

# report descriptor (27 bytes long)
REPORT_DESC_HEX='\x06\x00\xFF\x09\x01\xA1\x01\x15\x00\x26\xFF\x00\x75\x08\x95\x40\x09\x01\x81\x02\x09\x01\x91\x02\xC0'
REPORT_LEN=27
echo $REPORT_LEN | sudo tee functions/hid.usb0/report_length
echo -ne "$REPORT_DESC_HEX" | sudo tee functions/hid.usb0/report_desc > /dev/null

# Configuration
sudo mkdir -p configs/c.1/strings/0x409
echo "Config 1: HID" | sudo tee configs/c.1/strings/0x409/configuration
echo 120            | sudo tee configs/c.1/MaxPower

# Link function into configuration
sudo ln -s functions/hid.usb0 configs/c.1/

# Finally bind to UDC (onboard USB Device Controller)
UDC=$(ls /sys/class/udc | head -n1)
if [ -z "$UDC" ]; then
  echo "ERROR: No UDC found; gadget cannot be enabled" >&2
  exit 1
fi
echo $UDC | sudo tee UDC

echo "[*] Gadget up. Launching uhid..."
sudo "$SCRIPT_DIR/uhid"
echo "[*] All done."
