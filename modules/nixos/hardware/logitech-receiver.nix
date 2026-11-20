{ ... }:

{
  # The Logitech receiver (046d:c547) cut S3 short: with its wake enabled, sleep
  # ended after ~3 s with no input (ACPI GPE 0x08, the shared PCIe PME), but only
  # if the mouse was moved in the 5 min before suspending.
  # Likely cause: after wireless input the receiver queues data on USB interface
  # 2 (hiddev, unread); when the port suspends it raises a remote wakeup ~3 s
  # later. HID_QUIRK_ALWAYS_POLL (0x400) makes usbhid always read it; same fix as
  # the Bolt (c548) one, lore.kernel.org
  # 20260407-logi-bolt-hid-quirk-always-poll-v1-1-4dae0fda344e@collabora.com.
  # Checked on the desktop (kernel 6.18.55): sleep holds and the mouse wakes the
  # PC. One Bolt user still hit the bug with it on 7.1.6 (LKML, 2026-08-10).
  # If the PC wakes by itself after ~3 s again, fall back to a udev rule:
  #   ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device",
  #   ATTR{idVendor}=="046d", ATTR{idProduct}=="c547", ATTR{power/wakeup}="disabled"
  # (matches by vendor:product, so it survives USB port changes; the mouse then
  # no longer wakes the PC).
  boot.kernelParams = [ "usbhid.quirks=0x046d:0xc547:0x400" ];
}
