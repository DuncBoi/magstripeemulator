#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/uhid.h>
#include <sys/types.h>
#include <sys/stat.h>

// Example Track-2 data
static const char *track2 = ";4111111111111111=25121010000000000000?";

// 64-byte vendor-defined HID report descriptor
static const uint8_t report_desc[] = {
  0x06,0x00,0xFF,      // Usage Page (Vendor)
  0x09,0x01,          // Usage (Vendor Usage 1)
  0xA1,0x01,          // Collection (Application)
    0x15,0x00,        //   Logical Min (0)
    0x26,0xFF,0x00,   //   Logical Max (255)
    0x75,0x08,        //   Report Size (8 bits)
    0x95,0x40,        //   Report Count (64 bytes)
    0x09,0x01,        //   Usage (Vendor Usage 1)
    0x81,0x02,        //   Input (Data,Var,Abs)
    0x09,0x01,        //   Usage (Vendor Usage 1)
    0x91,0x02,        //   Output (Data,Var,Abs)
  0xC0                // End Collection
};

static void die(const char *msg) {
  perror(msg);
  exit(EXIT_FAILURE);
}

int main(void) {
  int fd = open("/dev/uhid", O_RDWR | O_CLOEXEC);
  if (fd < 0) die("open /dev/uhid");

  // 1) Create the gadget
  struct uhid_create2 cr = {
    .name    = "VirtualMagReader",
    .phys    = "uhid0",
    .uniq    = "",
    .vendor  = 0x1D6B,      // test VID
    .product = 0x0104,      // test PID
    .version = 0x0001,
    .country = 0,
    .rd_size = sizeof(report_desc),
    .rd_data = (void*)report_desc,
    .bus     = BUS_USB
  };
  if (write(fd, &cr, sizeof(cr)) < 0) die("UHID_CREATE2");
  printf("[+] Gadget created, waiting for host to enumerate...\n");
  sleep(1);

  // 2) Build one 64-byte report
  uint8_t report[64] = {0};
  size_t len = strnlen(track2, sizeof(report));
  memcpy(report, track2, len);

  // 3) Send it
  struct uhid_input2 inp = {
    .size = sizeof(report),
    .data = report
  };
  printf("[+] Sending swipe: %s\n", track2);
  if (write(fd, &inp, sizeof(inp)) < 0) die("UHID_INPUT2");

  sleep(1);

  // 4) Destroy it
  struct uhid_destroy dr = {};
  if (write(fd, &dr, sizeof(dr)) < 0) die("UHID_DESTROY");
  close(fd);
  printf("[+] Gadget destroyed. Done.\n");
  return 0;
}
