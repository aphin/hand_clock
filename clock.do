# DipTrace Auto-Generated DO File
bestsave off
grid via 0,0039
grid wire 0,0039
define (class Dip_Net_Class_0 Net@0 Net@1 GND RESET VCC SCK MISO MOSI CMD/DAT CE LEDA2 LEDA1 Net@12 Net@13 Net@14 Net@15 Net@16 Net@17)
circuit class Dip_Net_Class_0 (use_via DipViaStyle_0)
rule class Dip_Net_Class_0 (width 12,9921)
rule class Dip_Net_Class_0 (clearance 12,9921)
set pad_wire_necking on
bus diagonal
route 20
clean 2
route 25 16
clean 2
filter 5
recorner diagonal
