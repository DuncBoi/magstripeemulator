#!/bin/bash
set -e

CONFIG=/boot/config.txt
CMDLINE=/boot/cmdline.txt

echo "[*] Backing up boot configs…"
sudo cp "$CONFIG"{,.bak}
sudo cp "$CMDLINE"{,.bak}

echo "[*] Enabling dwc2 overlay in $CONFIG"
# only append if not already present
if ! grep -q '^dtoverlay=dwc2' "$CONFIG"; then
  echo 'dtoverlay=dwc2' | sudo tee -a "$CONFIG" >/dev/null
else
  echo "   already present"
fi

echo "[*] Enabling dwc2,libcomposite modules at boot in $CMDLINE"
if ! grep -q 'modules-load=dwc2,libcomposite' "$CMDLINE"; then
  sudo sed -i 's/\(rootwait\)/\1 modules-load=dwc2,libcomposite/' "$CMDLINE"
else
  echo "   already present"
fi

echo "[*] Done. Rebooting now to activate OTG mode…"
sudo reboot
