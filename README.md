# Virtual Magstripe Reader Setup

This repository sets up a USB HID gadget that emulates a magstripe reader.

## Quickstart

### 1. Make `boot.sh` executable and run it

```bash
chmod +x boot.sh
./boot.sh
```

This will reboot your computer in gadget mode

### 2. After reboot, navigate back to this directory

Once the system reboots, open a terminal and go back to the cloned project directory:

```bash
cd /path/to/this/project
```

### 3. Make `setup.sh` executable and run it

```bash
chmod +x setup.sh
./setup.sh
```

This will:

- Configure the USB HID gadget
- Compile the `uhid` binary using `make`
- Run the virtual magstripe swipe

## Requirements

- Linux system with USB gadget support (e.g., Raspberry Pi Zero, Pi 4 in OTG mode)
- Root access (`sudo`)
- `make` and build tools installed

## Notes

-every time you want to reset you will have to run the reboot script
