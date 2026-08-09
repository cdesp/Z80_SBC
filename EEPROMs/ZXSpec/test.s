                org $6000       

                JP START




START         LD IX,23778
                LD DE,17
                 JP MENTRY
               



FILESZER  DEFM "ERROR GETTING SIZE"
          DB 0


include loader.z80
include ..\main.z80
include ..\mmu.z80
include ..\bootloader\atl_ch376s.Z80
include ..\bootloader\atl_storage_new.Z80
include ..\bootloader\atl_serial.Z80
include ..\bootloader\atl_utils.Z80
INCLUDE VARS.Z80