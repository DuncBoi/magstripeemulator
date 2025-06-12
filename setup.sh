#!/bin/bash
set -e

GADGET_DIR=/sys/kernel/config/usb_gadget/magstripe_gadget

echo "[*] Cleaning up any old gadget…"
if [ -d "$GADGET_DIR" ]; then
  pushd "$GADGET_DIR" >/dev/null

  # 1) Unbind
  if [ -f UDC ] && [ -n "$(cat UDC)" ]; then
    echo "" | sudo tee UDC
  fi

  # 2) Unlink HID function from config
  sudo rm -f configs/c.1/hid.usb0

  # 3) Remove HID function directory
  sudo rmdir functions/hid.usb0

  # 4) Remove config strings
  sudo rmdir configs/c.1/strings/0x409

  # 5) Remove config
  sudo rmdir configs/c.1

  popd >/dev/null

  # 6) Remove gadget dir
  sudo rmdir "$GADGET_DIR"
fi

echo "[*] Loading kernel modules…"
sudo modprobe dwc2
sudo modprobe libcomposite
sudo mount -t configfs configfs /sys/kernel/config/ || true

echo "[*] Creating new gadget…"
sudo mkdir -p "$GADGET_DIR"
cd "$GADGET_DIR"

# Device IDs
echo 0x1d6b | sudo tee idVendor
echo 0x0104 | sudo tee idProduct
echo 0x0100 | sudo tee bcdDevice
echo 0x0200 | sudo tee bcdUSB

# Strings
sudo mkdir -p strings/0x409
echo "0123456789"              | sudo tee strings/0x409/serialnumber
echo "Xerox"                   | sudo tee strings/0x409/manufacturer
echo "Virtual Magstripe Reader"| sudo tee strings/0x409/product

# HID function
sudo mkdir -p functions/hid.usb0
echo 1 | sudo tee functions/hid.usb0/protocol
echo 1 | sudo tee functions/hid.usb0/subclass

# Report descriptor
REPORT_DESC_HEX='\x06\x00\xFF\x09\x01\xA1\x01\x15\x00\x26\xFF\x00\x75\x08\x95\x40\x09\x01\x81\x02\x09\x01\x91\x02\xC0'
REPORT_LEN=27
echo $REPORT_LEN | sudo tee functions/hid.usb0/report_desc_size
echo -ne "$REPORT_DESC_HEX" | sudo tee functions/hid.usb0/report_desc > /dev/null

# Configuration
sudo mkdir -p configs/c.1/strings/0x409
echo "Config 1: HID" | sudo tee configs/c.1/strings/0x409/configuration
echo 120            | sudo tee configs/c.1/MaxPower

# Link HID function in
sudo ln -s functions/hid.usb0 configs/c.1/

# Bind to UDC
UDC=$(ls /sys/class/udc | head -n1)
if [ -z "$UDC" ]; then
  echo "ERROR: no UDC found; gadget cannot be enabled" >&2
  exit 1
fi
echo $UDC | sudo tee UDC

echo "[*] Gadget up. Launching uhid…"
sudo ./uhid

echo "[*] All done."
