@ECHO OFF
"C:\Program Files\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "F:\Work\Hardware\HAND_CLOCK\firmware\labels.tmp" -fI -W+ie -C V2E -o "F:\Work\Hardware\HAND_CLOCK\firmware\clock.hex" -d "F:\Work\Hardware\HAND_CLOCK\firmware\clock.obj" -e "F:\Work\Hardware\HAND_CLOCK\firmware\clock.eep" -m "F:\Work\Hardware\HAND_CLOCK\firmware\clock.map" -l "F:\Work\Hardware\HAND_CLOCK\firmware\clock.lst" "F:\Work\Hardware\HAND_CLOCK\firmware\clock.asm"