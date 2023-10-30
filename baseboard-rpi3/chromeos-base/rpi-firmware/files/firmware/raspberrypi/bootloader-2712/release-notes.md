# Raspberry Pi5 bootloader EEPROM release notes

2023-09-28: vcgencmd pmic_read_adcs fixes (automatic update)
 
* Fix the LDO names and current scaling codes
* Manufacturing test updates

2023-09-21: Power button and ACT LED improvements

* Fix bug where button press was not monitor for USB-C power supplies
  that were detected as < 3A.
* In USB boot mode automatically select max-current during a reboot
  (but not power on reset) to improve OS installation experience.
* USB-MSD stability improvements
* Remove the HALT error pattern and go to halt/standby immediately.
* Add support for HAT map.


2023-09-13: Initial release

* Initial manufacturing software
* Network Install is not available in this version
* rpi-eeprom-update uses self-update on Pi5 rather than recovery.bin.
  so that the update mechanism is the same on all boot-modes and the
  boot file-system is never modified by the firmware/recovery.bin.
  recovery.bin is still used by RPi Imager - bootloader update SD card images.
* Pi4 and Pi4 bootloader images and recovery.bin are not compatible.
  The 2711/2712 boot ROM ignores incompatible recovery.bin files.
