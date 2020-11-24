# Raspberry Pi4 bootloader EEPROM release notes

USB MSD boot also requires updated beta GPU firmware. Please read
https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md

## 2020-08-10 Promote 2020-07-31 release to STABLE
   * The USB port power management change from the last BETA improves
     compatiblity for devices which during reset with no regressions reported.
     Make this the latest stable release.

## 2020-07-31 Standardize USB port power control accross board revisions - BETA
   * Turn off USB port power for 1-second regardless of boot-mode. This appears
     to resolve an issue on R1.3 and older board revisions where some USB
     devices would fail upon reboot. On R1.4 USB port power is turned off
     automatically by the PMIC so this is just held in reset for longer. For
     earlier board revisions the USB port power is explicitly turned off via
     XHCI.
     This can be overriden via USB_MSD_PWR_OFF_TIME in the EEPROM config.
   * Update to the latest Broadcom memsys FW - no significant functional change.

## 2020-07-20 Promote 2020-07-16 bootloader and VL805 0138A1 FW to stable - STABLE
   * Promote the latest beta to stable as the next production firmware release
     candidate.
     The main difference between this and the previous stable version is
     the VL805 FW update. 

## 2020-07-16 Update VL805 FW to 0138A1 and add optional EEPROM write-protect - BETA
   * Patch previous 2020-07-16 from c44ee87f -> 45291ce6 to fix a CM4 specific
     issue which does not impact Model B
   * Update the VL805 embedded / standalone FW version to 0138A1
      *  User settings of the ASPM bits in the PCI configuration space
         link control register are now maintained
      * Better full-speed Isochronous endpoint support
   * Add eeprom_write_protect config.txt variable which if set configures
     the non-volatile status register bits to define the write protect
     regions.
      * If 1 then configure the write protect regions for both the
        bootloader and VLI EEPROMs to cover the entire EEPROM.
      * If zero then clear all write protect bits.
      * If missing or -1 then don't change the current state.
   * The write protect is only effective if the /WP pin is pulled low
     e.g. by shorting TP5 to ground.
   * WARNING: Previous versions of the bootloader, recovery.bin and vl805
     tool do NOT clear the non-volatile status bits for the VL805 SPI EEPROM.
     Consequently, installing an older version will fail/hang if the write
     protect bits have not been cleared first (eeprom_write_protect=0)
   * Update the vl805 user-space tool to clear the WP bits.
   * Add recovery_wait config.txt option which if set to 1 forces the EEPROM
     rescue image and flashes the activity LED forever. This is intended for
     use with an SD card image which just contains recovery.bin + config.txt
     and is used to set/clear WP on multiple boards.
   * The write protect functionality works with self-update mode, however,
     the bootloader must have already been updated to the version supporting
     write protect first i.e. at least two reboots are required.
   * Update the HDMI diagnostics screen to display 'RO' after the EEPROM version
     if the write status register for the bootloader SPI EEPROM has write protect
     bits defined. This does NOT attempt to verify if /WP is low.

## 2020-07-06 Tweak USB port power and clear ACT LED after SPI - BETA
   * Increase port power off limit to 5 seconds.
   * Increase the port power off default to 1 second. This seems to cover most
     commonly seen USB MSD devices which require the USB port power to be disabled
     after the USB HC chip is reset.
   * Reset activity LED after SPI access to reduce the number of spurious LED flashes.
   * Add SPI error diagnostic error code (3 long 1 short) if SPI commands timeout.
     (So far this failure has not been observed on failed boards)

## 2020-06-17 Promote 2020-06-15 to STABLE
   * Promote the latest beta EEPROM and recovery.bin to stable and
     feature freeze USB MSD support until a production release is ready.

## 2020-06-15 Increase default USB port power delay - BETA
   * Increase the default power off delay to 500ms following more
     interop testing.
   * Make the USB port power off time configurable via the USB_MSD_PWR_OFF_TIME
     config. The range may be set between 250 and 1000ms. Zero means no port
     power off.
   * Fix some issues in XHCI endpoint configuration where the code was wrong
     but does not fail with the current VL805 FW.

## 2020-06-12 Improve support for powered USB SATA devices - BETA
   * Reset Ethernet MAC + PHY if final boot mode is not network boot
     See: Kernel warning and network failure when attempting to use the network after bootloader times out. #144
   * Improve handling of multiple bootable USB devices and remove USB_MSD_BOOT_MAX_RETRIES
   * Resolve: No DHCPACK with DHCP relay agent #58
   * Toggle USB root hub port power for 200ms on the first USB MSD boot attempt
     See: Bootloader can't boot via USB-HDD after system reboot #151
   * Update bootloader handover to support uart_2ndstage - requires
     a newer start.elf firmware which will be via rpi-update.
   * Assert PCIe fundamental reset if the final bootmode was not USB-MSD because
     the OS might not do this before starting XHCI.

## 2020-06-03 Bootmode tweaks and fix issue with > 4TB drives - BETA
   * Resolve: Unable to boot from USB MSD - Seagate 5Tb HDD backup drive #139
   * Increase USB MSD timeout from 10 to 20 seconds.
   * Max retries now default to zero because the default BOOT_ORDER includes
     restart (0xf). Therefore, each boot-mode is now tried once before moving
     to the next mode. The retries mechanism is largely redudant now that
     the loop/restart mode exists.
   * If TFTP fails and network boot retries > 0 then wait 5 seconds before
     retrying to avoid overloading a misconfigured TFTP server.
   * Map undefined boot-modes in BOOT_ORDER to SD (0x1) instead of stopping.
   * Add missing pieeprom-2020-05-28

## 2020-05-28 Secondary fix for VL805 readback issue - BETA
    * Re-upload 2020-05-28 after Git issue
    * rpi-eeprom-update for new board revisions

## 2020-05-27 Fix DPI issue - BETA
    * Resolve: DPI failure after HDMI diagnostics screen in beta bootloader #133
    * Resolve: VL805 readback failure in the bootloader #134

## 2020-05-26 USB MSD updates - BETA
    * Resolve: USB boot fails if the GPT contains no basic data or EFI partitions #130
    * Resolve: Fix default BOOT_ORDER in mass storage beta #129
    * Resolve: Add support for booting from a "superfloppy" disk #120
    * Resolve: USB MSD timeout message - incorrect units #131
    * Resolve: Recognize efi partition (0xef) as a valid boot #126
    * The HDMI diagnostics screen now displays the most significant bytes
      of the SHA-256 of the config.txt file.

## 2020-05-26 rpi-eeprom-update
    * Mark USE_FLASHROM as deprecated.
    * Resolve: Unnecessary check for '*.elf' in BOOTFS #92
    * Update help for FIRMWARE_RELEASE_STATUS.

## 2020-05-15 Add pieeprom-2020-05-15 beta with USB boot
    * USB mass storage boot will NOT work without the updated firmware
      start.elf binaries. These will probably be released via rpi-update
      in a few days time.
      This release simply helps to validate if there are regressions in
      the current SD and Network boot modes.

      * SELF_UPDATE and bootloader_update are now enabled by default.

## 2020-05-11 Garbage collect old binaries
    * Now that 2020-04-16 is has been released as the default production
      release move the old binaries to an old (deprecated) directory.
      These can be removed for the APT package to reduce disk space.

## Promote 2020-04-16 EEPROM release critical
    * Make this the default release for all users. This supports network
      boot, configurable boot order and HDMI diagnostics screen.

## 2020-04-16 Promote to stable
    * The PLL analog changes in the beta release never made it to stable.
      Skip straight 2020-04-16 to synchronize releases.

## 2020-04-16 Revert PLL analog changes
    * This seems to cause problems on some firmware releases if enable_tvout
      is set due to different behaviour in PLL management.

## 2020-04-12 Update beta+stable recovery.bin
    * If the VL805 image was updated but the bootloader was not then
      recovery.bin would incorrectly switch to infinite flashing activity
      LED pattern used in the rescue image to prevent infinite reboots.
      Fix recovery.bin to reboot in this case. The current 'critical'
      release does not have this problem.
    * Fix uart_2ndstage logging in beta/stable recovery image.
    * Change recovery.bin to reboot instead of displaying an error patern
      if there are no EEPROM images. The Raspberry Pi Image makes it very
      difficult to create a broken rescue image but a stray recovery.bin
      could stop Raspbian from booting.
    * Fix detection of VL805 EEPROM in recovery.bin

    N.B. These recovery.bin file used for critical updates and the rescue
    image does not suffer from these bugs.

## 2020-04-09 Add 2020-04-09 beta firmware.
    * Experimental tweaks for PLL analog setup to reduced jitter and
      improve PCIe reliability on slower silicon.

## 2020-04-07 Promote 2020-03-19 beta firmware to stable.
    * No major bugs reported. Promote this to stable as a step
      towards getting HDMI diagnostics into the default firmware
      via a critical update.

## 2020-03-19 Add 2020-03-19 beta firmware
    * Minor mods for manufacture test.

## 2020-03-16 Add 2020-03-16 beta firmware
    * Fix DHCP Option97 GUID generation. The MAC LSB portion was previously
      always zero.

## 2020-03-11 Add 2020-03-04 beta firmware recovery
    * Support static IP address configuration. The following fields may be
      set manually using dotted decimal address. If set, then DHCP if skipped.
       * CLIENT_IP
       * SUBNET
       * GATEWAY
       * TFTP_IP
    * If a fatal bootloader error occurs then an HDMI diagnostics screen is
      displayed at VGA/DVI resolution on both outputs for two minutes.
      This may be disabled by setting DISABLE_HDMI=1 in the EEPROM
      configuration OR setting display_splash=1 in config.txt.
    * Allow the PXE menu option to match a custom string specified by
      PXE_OPTION43. The default is still "Raspberry Pi Boot"
    * DHCP_OPTION97 - The default GUID has now changed to
      RPI4+BOARD_ID+ETH_MAC_LSB+SERIAL in order to make it easier to
      automatically identify Raspberry Pi computers. The old behaviour
      is enabled by setting DHCP_OPTION97=0 which simply repeats the serial
      number 4 times.
    * SELF_UPDATE. If SELF_UPDATE is set to 1 in the EEPROM configuration AND
      config.txt contains bootloader_update=1 then the bootloader will looking
      for pieeprom.upd and vl805.bin and apply these firmware files if
      they are different to the current image, before doing a watchdog reset.
      This should make it easier to update the bootloader for network
      booted setups because an SD card is not required for recovery.bin.
      As usual, TFTP should only be used on private networks because the
      protocol is not secure against spoofing.
    * recovery.bin. The beta recovery.bin will now display a green screen
      via HDMI if successful or red if a failure occurs.

## 2020-02-27 rpi-eeprom-update & firmware
    * Remove the dependency check for the vl805 utility. This is deprecated
      and there is no 64-bit version. The file is still available in Github
      for anyone who wants to continue using USE_FLASHROM or create their
      own scripts.
    * Add a stable firmware directory based on the latest beta release.
      Stable should be interpreted as feature-freeze releases. In this
      case the core network boot is stable enough for most scenarios
      and this de-risks adding new more experimental features in the
      beta folder.

## 2020-01-22 - vl805 00137ad
    * Set the default/critical vl805 version to be 00137ad. This has the
      same power savings as 0137ab but with fixes for USB webcams.

## 2020-01-17 - Git 5e86aac5f (BETA) RC4
    * Handle DHCP option 0 - padding
    * Fix SD card voltage detection

## 2020-01-14 - rpi-eeprom-config
    * Fix padding calculation

## 2020-01-09 - Git df0ff18c (BETA) RC3
    * Fix parsing of multiple menu entries in PXE options.
    * Fix regression in IP address parsing

## 2019-12-03 - Git f0d7269d4 (BETA) RC2
    * Fix handling of multiple menu options with TFTP Option43
    * Ignore unsupported modes in BOOT_ORDER instead of stopping.

## 2019-11-18 - Git b6a7593d6 (BETA) RC1
    First release candidate before this beta is moved to a stable release series.

    * Avoid resetting TFTP prefix after retries or if start4.elf is not found.
    * Add MAC_ADDRESS option which allows the OTP Ethernet MAC address to be
      overriden. An VideoCore firmware update will propagate this forced
      mac address to device-tree/cmdline in the near future.
    * Various internal refactorings to prepare for USB MSD storage boot in
      the next beta-series.
    * Enable high-speed mode for EMMC cards.

## 2019-10-17 - rpi-eeprom-update + recovery.bin
    * New beta recovery.bin which can update the VLI EEPROM before
      start.elf is loaded. This is the recommended and default method
      because no USB devices will be in use at this stage.
    * Extend the USE_FLASHROM configuration to use the vl805 tool
      to program the VL805 directly.
    * Generate SHA256 checksums in .sig files for the bootloader and
      and VL805 images. This is required by the new recovery.bin to
      guard against corrupted files being flashed to the EEPROM(s).
    * Various variable renames to distinguish between the bootloader
      and the VL805 images.

## 2019-10-16 - Git 18472066 (BETA)
   * Ignore trailing characters when parsing in PXE boot menu option.
   * Improve error handling with unformatted sd-cards.
## 2019-10-08 - Git 26dd3686c (BETA)
   * TFTP now uses RFC2348 blksize option to get 1024 byte blocks if the server supports it.
   * Fix DHCP handling of SI_ADDR
   * TFTP_PREFIX and TFTP_PREFIX_STR options for mac-address or string literal prefix.
   * Improved support for standard capacity and SDv1 cards.

## 2019-09-25 - Git 4d9824321 (BETA)
   * Increase TFTP timeout to 30s as default & bootconf.txt
   * Fix intermittent boot freeze/slowdown issue after loading start.elf
   * Don't load start.elf during network boot if start4.elf exists but the download times out.
## 2019-09-23 - Git c67e8bb3 (BETA)
   * Add support for network boot
   * Configurable ordering for boot modes (BOOT_ORDER and SD/NET_BOOT retries)

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
