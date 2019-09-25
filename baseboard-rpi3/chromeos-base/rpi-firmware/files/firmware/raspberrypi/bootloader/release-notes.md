# Raspberry Pi4 bootloader EEPROM release notes

## 2019-09-10 - Git f626c772
   * Configure ethernet RGMII pins at power on. This is a minor change which
     which may improve reliability of ethernet for some users.

## 2019-09-05 - Git d8189ed4 - (BETA)
   * Update SDRAM setup to reduce power consumption.

## 2019-07-15 - Git 514670a2
   * Turn green LED activity off on halt.
   * Pad embedded config file with spaces for easier editing by end users.
   * Halt now behaves the same as earlier Pi models to improve power behavior at halt for HATs. 
   * WAKE_ON_GPIO now defaults to 1 in the EEPROM config file.
   * POWER_OFF_ON_HALT setting added defaulting to zero. Set this to 1 to restore the behavior where 'sudo halt' powers off all PMIC output.
   * If WAKE_ON_GPIO=1 then POWER_OFF_ON_HALT is ignored.
   * Load start4db.elf / fixup4db.dat in preference to start_db.elf / fixup_db.dat on Pi4.
   * Embed BUILD_TIMESTAMP in the EEPROM image to assist version checking.

## 2019-05-10 - Git d2402c53 (RC2.1)
   * First production version.
