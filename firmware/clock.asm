; �������� ��� �������� ����� �� ATMEGA48PA, ������� Siemens C60, 6 ������
; TODO
; 1. ������� ����� ��������� ��������� ������� (� ���������� ������������� ��������)
; 2. ������� ������� ������ ����������, ����� �� ��������� ������ ���������


;#define DEBUG

; ��� ����:
; �������� GPIORx
; GPIOR0.0 - ���� �������� BCD
; GPIOR0.1 - ������������ ��� ��������������� ���� ��� ������ ����������
; GPIOR0.2 - ��������������� � 1 ������ ������� ���� �������
; GPIOR0.3 - ...������ �������
; GPIOR0.4 - ...������
; GPIOR0.5 - ...���
; GPIOR0.6 - ...����
; GPIOR0.7 - ...�����

.nolist
.include "C:\Program Files\Atmel\AVR Tools\AvrAssembler2\Appnotes\m48PAdef.inc"
.list

.include "definitions.inc"

.cseg ; ������� ����
.org 0

rjmp Start
; ����������
rjmp INT0r
rjmp INT1r
rjmp PCINT0r
rjmp PCINT1r
rjmp PCINT2r
rjmp WDT
rjmp T2_COMPA
rjmp T2_COMPB
rjmp T2_OVF
rjmp T1_CAPT
rjmp T1_COMPA
rjmp T1_COMPB
rjmp T1_OVF
rjmp T0_COMPA
rjmp T0_COMPB
rjmp T0_OVF
rjmp SPI_STC
rjmp USART_RX
rjmp USART_UDRE
rjmp USART_TX
rjmp AnalogDC
rjmp EE_RDY
rjmp AnalogCMP
rjmp TWI
rjmp SPM_RDY

Start:

.include "init.inc"
	
	rcall LCD_IdleOn

main:

	sleep

; ���� ���������� TC2 ��� � ���-����� �� RTC
	ldi tmp, 0x00
	sts OCR2B, tmp
wtr:
	lds tmp, ASSR
	sbrc tmp, OCR2BUB
	rjmp wtr

; ��������� �����
	tst tmp2
	brne m_cont
	BEEP_OFF
m_cont:
	cpi mode, 0x00
	brne m_mode1

; ����� 0 - ������ ����, ��������� 5 ������ �� �������, ����� Idle
	sbis GPIOR0, 3	; ��������� ��������� ������ �������
	rjmp kbd_hand

	ldi tmp, 3
	mov lcd_x, tmp
	ldi tmp, 28
	mov lcd_y, tmp
	rcall LCD_DrawTime
	rcall LCD_DrawDate
	rjmp kbd_hand
; ����� 1 - ������ ����-�����, ��������� ��������, ����� Normal, ������ � ���������� 0.1 ���
m_mode1:
	cpi mode, 0x01
	brne m_mode2
	sbis GPIOR0, 2
	rjmp kbd_hand
	
;	ldi refresh, 0b00011111

	ldi tmp, 3
	mov lcd_x, tmp
	ldi tmp, 28
	mov lcd_y, tmp

	rcall LCD_DrawTime
	rcall LCD_DrawDate
	
	rjmp kbd_hand
m_mode2:				

kbd_hand:
; ���� ��� ������� �� ������
	mov tmp, kbd_press
	ori tmp, 0b11000000
	cpi tmp, 0xFF
	breq kbd_hcont
	BEEP_ON
	ldi tmp2, 5
kbd_hcont:
	cpi mode, 0x00
	brne m_kbd_mode1
; ���������� ������ ������ 0
	sbrc kbd_press, 3
	rjmp nx_b
	LED_ON
	rcall LCD_IdleOff
	ldi tmp, 50
	mov led_timer, tmp
nx_b:
	sbrc kbd_press, 5
	rjmp nx_b1
	inc mode
	rcall LCD_Clear
	rcall LCD_IdleOff
	ori refresh, 0b00011111
	LED_ON
nx_b1:
	rjmp main
m_kbd_mode1:
; ���������� ������ ������ 1
	cpi mode, 0x01
	breq m_kbd_mode1_cont
	rjmp m_kbd_mode2
m_kbd_mode1_cont:
	sbrc kbd_press, 5
	rjmp nx_b_m1
	clr mode
	rcall LCD_Clear
	rcall LCD_IdleOn
	ori refresh, 0b00011111
	LED_OFF
nx_b_m1:	; ������ 4, 1 (������� ����� � ������ ��������������) - ����� ������������� ��������
	sbrc kbd_press, 4
	rjmp nx_b1_m1
	ori refresh, 0b00011111
	tst mode_tmp
	breq m_mdtmp_max_set
	dec mode_tmp
	rjmp nx_b1_m1
m_mdtmp_max_set:
	ldi mode_tmp, 0x06
nx_b1_m1:
	sbrc kbd_press, 1
	rjmp nx_b2_m1
	ori refresh, 0b00011111
	inc mode_tmp
	cpi mode_tmp, 0x07
	brne nx_b2_m1
	clr mode_tmp
nx_b2_m1: ; ������ 0, 2 (������ ������� � ������ ��������������) - ��������� ��������� ��������
	sbrs kbd_press, 0
	rjmp nx_b2_cont
	sbrs kbd_press, 2
	rjmp nx_b2_cont
	rjmp nx_b3_m1

nx_b2_cont:
	ori refresh, 0b00011111
	LAPZ corr_table	; ������� ������� �������������� ������� (��� ��������)
	rcall mt_offset

	lpm tmp, Z+
	lpm tmp1, Z	; tmp1:tmp - ����� ������������� ��������
	mov ZH, tmp1
	mov ZL, tmp

	cli	; ��������� ����������, �.�. ������ �����
	sbrc kbd_press, 0	; ������ 1 - ���������
	rjmp val_dec
	rcall BCD_Inc	; ����������� �������� � ������ 
	rjmp val_check
val_dec:
	ldi tmp, 0x99
	rcall BCD_Add	; ���������� BCD_Dec
val_check:
	ld tmp, Z	; � tmp ����� ����� �����������
	push tmp
	cpi mode_tmp, 0x02
	breq sec_corr
	cpi mode_tmp, 0x03
	breq day_corr
	cpi mode_tmp, 0x06
	breq no_corr
hr_mn_mo:
; ��� �����, ����� � ������
	pop tmp
	push ZH
	push ZL
	LAPZ corr_max_value
	rcall mt_offset
	lpm tmp1, Z	; ��������� ����� ������������� �������� �������������� ���������
	pop ZL
	pop ZH
	cp tmp, tmp1
	brlo no_corr	; ��������� �� �����
	clr tmp
	st Z, tmp
	rjmp no_corr
sec_corr:
; ��� ������ (���� � ��� ��������)
	clr tmp
	st Z, tmp	; �������� ����� ������
	sbiw ZL, 0x01
	st Z, tmp	; �������� ���� ������� ����� ������
	rcall Tmp_to_TCNT2	; ����� �������� �������
	LASZ sec_cnt
	st Z, tmp	; �������� ������� ��������� 0.1 ���
	rjmp no_corr
day_corr:
; � ����� ����� ����������������� ������� �����	
	push ZH	; � ZH:ZL ��������� �� ���� � ����������� ������
	push ZL
	LASZ month
	ld tmp, Z	; �����
	sbrc tmp, 4
	subi tmp, 6	; � tmp ����� ������ � binary
	LAPZ month_len
	add ZL, tmp
	clr tmp
	adc ZH, tmp
	lpm tmp1, Z	; ������ ��� ����� ���� � ������
	pop ZL
	pop ZH
	pop tmp	; tmp - ������� �����
	cpi tmp, 0x00
	breq day_cr1
	cp tmp, tmp1
	brlo no_corr
	ldi tmp, 0x01
	rjmp day_cr2
day_cr1:
	mov tmp, tmp1
	dec tmp ; ����� ����� � ��� BCD_Inc, �.�. ������������ �� �����
day_cr2:
	st Z, tmp
no_corr:
	sei	; �������� ���������� �������
nx_b3_m1:
	rjmp main

m_kbd_mode2:
; ���������� ������ ������ 2
	sbrc kbd_press, 5
	rjmp nx_b_m2
	clr mode
	rcall LCD_Clear
	rcall LCD_IdleOn
	LED_OFF
nx_b_m2:
	rjmp main

; ��� �������� flash ������ �������� ��� mode_tmp ������� � ��������� ������������
mt_offset:
	push mode_tmp
	lsl mode_tmp
	add ZL, mode_tmp
	clr mode_tmp
	adc ZH, mode_tmp
	pop mode_tmp
	ret
;-------- ����� ��������� �����

INT0r:
INT1r:
PCINT0r:
PCINT1r:
PCINT2r:
WDT:
T2_OVF:
T2_COMPB:
T1_CAPT:
T1_COMPA:
T1_COMPB:
T1_OVF:
T0_COMPA:
T0_COMPB:
T0_OVF:
SPI_STC:
USART_RX:
USART_UDRE:
USART_TX:
AnalogDC:
EE_RDY:
AnalogCMP:
TWI:
SPM_RDY:
	reti

Tmp_to_TCNT2:
	push tmp
	sts TCNT2, tmp
wl_tcnt_z:
	lds tmp, ASSR
	sbrc tmp, 4
	rjmp wl_tcnt_z	
	pop tmp
	ret

T2_COMPA:		; ���������� ���������� �� �������
	push tmp
	in tmp, SREG
	push tmp

	push ZH
	push ZL

	in tmp, GPIOR0
	andi tmp, 0b00000011
	out GPIOR0, tmp			; ���������� ����� ��������� �������

	rcall KBD_Check ; ���� ������
	
	ldi ZH, high(sec_duration)
	ldi ZL, low(sec_duration)
	ld tmp, Z
	inc sec_part_cnt
	cp sec_part_cnt, tmp
	brne t2_end

; ������ 0.1 �������
	sbi GPIOR0, 2	; ���������� ����
	
	rcall Time_Date_Inc	; ��������� ����-�������
	clr sec_part_cnt	; �������� �������
; ����������, � ����� ������ �������� ����
	cpi mode, 0x00
	brne tc2_mode1
; ����� 0 - ���������� ����������
	tst led_timer		; ������ � ����������
	breq t2_end
	dec led_timer
	brne t2_end
	LED_OFF
	rcall LCD_IdleOn
	rjmp t2_end

tc2_mode1:
; ����� 1 - ��������� ����, �������, �������������
	nop

t2_end:
	tst tmp2
	breq t2_out1
	dec tmp2
t2_out1:
	pop ZL
	pop ZH
t2_out:
	pop tmp
	out SREG, tmp
	pop tmp
	reti

;-------- ������������
KBD_Check:
	push tmp
	sbis GPIOR0, 1
	rjmp row0_active
; row1 active
	in tmp, PIND
	andi tmp, 0b01110000
	lsr tmp
	or kbd, tmp
	ori tmp, 0b11000111
	and kbd, tmp
	sbi PORTD, 2
	nop
	cbi PORTD, 3
	nop
	cbi GPIOR0, 1
	rjmp kbd_end
row0_active:
	in tmp, PIND
	andi tmp, 0b01110000
	lsr tmp
	lsr tmp
	lsr tmp
	lsr tmp
	or kbd, tmp
	ori tmp, 0b11111000
	and kbd, tmp
	sbi PORTD, 3
	nop
	cbi PORTD, 2
	nop
	sbi GPIOR0, 1
kbd_end:
	ldi tmp, 0b00111111
	and kbd, tmp
	cp kbd, tmp
	brne kbd_ret
	ldi tmp, 0x80
	or kbd,tmp	; ���������� ���� ������� (��� ��������)
kbd_ret:
; ����� ��������� kbd_press � kbd_release
	mov tmp, kbd
	eor tmp, kbd_prev	; tmp - �������� 1-�� ���� ������ �������� ���� ���������
	ori tmp, 0b11000000	; ������ ��������
	mov kbd_press, kbd_prev	; ����� 0 ���� ������ ������ � ������� �����
	mov kbd_release, kbd	; ����� 0 ���� ������ ������ � ���� �����
	and kbd_press, tmp ; ���� ������ �������� ���� �������� � ��� ������ � ���� �����, �� � ������ ���� ����� 1 (������ ������)
	and kbd_release, tmp ; ���� ������ ���� ������ � ������� �����, �� �������� ���� ��������, �� � ������ ���� ����� 1 (������ ��������)
	com kbd_press
	com kbd_release
	mov kbd_prev, kbd	; ��������� �������� ������ ����������

	pop tmp
	ret
;----------------------
LCD_DrawTime:
	push ZH
	push ZL
	push tmp
	push tmp1

	ldi tmp, 2
	mov lcd_mx, tmp
	ldi tmp, 3
	mov lcd_my, tmp
	ldi tmp1, 0xFF

	sbrs refresh, 1
	rjmp drw_clk_minute_skip
	andi refresh, 0b11111101
	LASZ hour	; ������ ����
	ld tmp, Z
	
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_clk_hrd
	cpi mode_tmp, 0x00
	brne drw_clk_hrd
	rcall Exch_bkg_frg
drw_clk_hrd:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color
	ldi tmp,':'
	rcall LCD_DrawChar
	rjmp drw_clk_minute
drw_clk_minute_skip:
	ldi tmp, 32
	add lcd_x, tmp
drw_clk_minute:
	sbrs refresh, 0
	rjmp drw_clk_sec_skip
	andi refresh, 0b11111110
	ldi tmp, 16
	add lcd_x, tmp
	LASZ minute
	ld tmp, Z
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_clk_mnd
	cpi mode_tmp, 0x01
	brne drw_clk_mnd
	rcall Exch_bkg_frg
drw_clk_mnd:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color
	rjmp drw_clk_sec
drw_clk_sec_skip:
	ldi tmp, 32+16
	add lcd_x, tmp
drw_clk_sec:	; ������ �������
	ldi tmp, 1
	mov lcd_mx, tmp
	mov lcd_my, tmp
	ldi tmp, 14
	add lcd_y, tmp

	LASZ second
	ld tmp, Z
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_clk_sed
	cpi mode_tmp, 0x02
	brne drw_clk_sed
	rcall Exch_bkg_frg
drw_clk_sed:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color

	pop tmp1
	pop tmp
	pop ZL
	pop ZH
	ret
;---------------------
Time_Date_Inc:
	push ZH
	push ZL
	push tmp

	ldi ZH, high(dsecond)
	ldi ZL, low(dsecond)
	rcall BCD_Inc	; ���� ������� (�������� ���������� sec_part)
	ld tmp, Z
	cpi tmp, sec_part
	breq tdi_cnt1
	rjmp tdi_end
tdi_cnt1:
	clr tmp
	sbi GPIOR0, 3
	st Z+, tmp		
	rcall BCD_Inc	; �������
	ld tmp, Z
	cpi tmp, 0x60
	breq tdi_cnt2
	rjmp tdi_end
tdi_cnt2:
	clr tmp
	sbi GPIOR0, 4
	ori refresh, 0b00000001
	st Z+, tmp
	rcall BCD_Inc ; ������
	ld tmp, Z
	cpi tmp, 0x60
	breq tdi_cnt3
	rjmp tdi_end
tdi_cnt3:
	clr tmp
	sbi GPIOR0, 5
	ori refresh, 0b00000010
	st Z+, tmp
	rcall BCD_Inc ; ����
	ld tmp, Z
	cpi tmp, 0x24
	brne tdi_end
	clr tmp
	sbi GPIOR0, 6
	ori refresh, 0b00000100
	st Z+, tmp
	
	push ZH	; ��� ������
	push ZL
	ldi ZH, high(day_of_week)
	ldi ZL, low(day_of_week)
	ld tmp, Z
	inc tmp
	cpi tmp, 0x07
	brne tdi_cnt
	clr tmp
tdi_cnt:
	st Z, tmp
	pop ZL
	pop ZH

	rcall BCD_Inc ; ���
	ld tmp, Z
; �������� ����� ���� � ������ � ������� tmp1
	push tmp1
	push ZH
	push ZL
	push tmp
	ldi ZH, high(month)
	ldi ZL, low(month)
	ld tmp, Z	; � tmp - ����� ������ � ������� BCD
	sbrc tmp, 4
	subi tmp, 6	; � tmp ����� ������ � binary
	dec tmp
	ldi ZH, high(month_len<<1)
	ldi ZL, low(month_len<<1)
	add ZL, tmp
	ldi tmp, 0x00
	adc ZH, tmp
	lpm tmp1, Z
	pop tmp
	pop ZL
	pop ZH
	cp tmp, tmp1
	pop tmp1
	brne tdi_end
	ldi tmp, 0x01
	sbi GPIOR0, 7
	ori refresh, 0b00001000
	st Z+, tmp
	rcall BCD_Inc ; ������
	ld tmp, Z
	cpi tmp, 0x13
	brne tdi_end
	ori refresh, 0b00010000
	ldi tmp, 0x01
	st Z+, tmp
	rcall BCD_Inc ; ����
	sbis GPIOR0, 0
	rjmp tdi_end
	adiw ZL, 0x01
	rcall BCD_Inc
tdi_end:
	pop tmp
	pop ZL
	pop ZH
	ret
;----------------------
BCD_Add:
; in: Z - ��������� �� BCD ����� � ������
;     tmp - ������ ��������� (BCD)
; out: ����� �� ������ Z
; GPIOR0(bit0) - BCD carry
	
	push tmp1
	push tmp

	cbi GPIOR0, 0
	ld tmp1, Z
	add tmp1, tmp
	brhs lsd_correct
	push tmp1
	andi tmp1, 0x0F
	cpi tmp1, 0x0A
	pop tmp1
	brlo msd
lsd_correct:
	ldi tmp, 0x06
	add tmp1, tmp
msd:
	push tmp1
	andi tmp1, 0xF0
	cpi tmp1, 0xA0
	pop tmp1
	brlo bcd_end
	ldi tmp, 0x60
	add tmp1, tmp
	brcc bcd_end
	sbi GPIOR0, 0 
bcd_end:
	st Z, tmp1

	pop tmp
	pop tmp1	
	ret
;-------------------
BCD_Inc:
; in: Z - ��������� �� BCD ����� � ������
; out: ����� �� ������ Z
	push tmp
	ldi tmp, 0x01
	rcall BCD_Add
	pop tmp
	ret
;-------------------
Send_SPI:
SPI_Send:
	push tmp
	out SPDR, tmp
#ifndef DEBUG
spi_wait:
	in tmp, SPSR
	sbrs tmp, SPIF
	rjmp spi_wait
#endif
	pop tmp
	ret	
;--------------------
delay_10us:
	push tmp
	ldi tmp, 24

delay_loop:
	dec tmp
	brne delay_loop

	pop tmp
	ret
;--------------------
delay_100ms:
#ifndef DEBUG
	ldi tmp2, 16
d100_w:
	cpi tmp2, 0x00
	brne d100_w
#endif
	ret
;--------------------
delay_10ms:
#ifndef DEBUG
	ldi tmp2, 2
d10_w:
	cpi tmp2, 0x00
	brne d10_w
#endif
	ret
;--------------------
LCD_DrawDate:
	push ZH
	push ZL
	push tmp
	push tmp1

	ldi tmp1, 0xFF

	ldi tmp, 1
	mov lcd_mx, tmp
	mov lcd_my, tmp

	ldi tmp, 0x05
	mov lcd_y, tmp

	LASZ day

	sbrs refresh, 2
	rjmp drw_dat_end	; ���� �� ���� �������� ����, �� � "���������" �� ���� �������� ���, ����� � ���� ������

	andi refresh, 0b11111011
	mov lcd_x, tmp ; ������ �����
	ld tmp, Z

	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_day
	cpi mode_tmp, 0x03
	brne drw_dat_day
	rcall Exch_bkg_frg
drw_dat_day:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color

	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_dayw
	cpi mode_tmp, 0x04
	brne drw_dat_dayw
	rcall Exch_bkg_frg
drw_dat_dayw:
	rcall LCD_DrawDayOfWeek
	pop frg_color
	pop bkg_color

	ldi tmp, 0x05
	mov lcd_y, tmp
	LASZ day

	sbrs refresh, 3
	rjmp drw_dat_end

	andi refresh, 0b11110111
	ldi tmp, 0x05+(0x08*3)
	mov lcd_x, tmp

	adiw ZL, 0x01
	ld tmp, Z+
	sbrc tmp, 4
	subi tmp, 6	; � tmp ����� ������ � binary
	lsl tmp
	lsl tmp
	push ZH
	push ZL
	LAPZ month_names
	add ZL, tmp
	ldi tmp, 0x00
	adc ZH, tmp	; Z ��������� �� �������� ������

	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_mon
	cpi mode_tmp, 0x05
	brne drw_dat_mon
	rcall Exch_bkg_frg
drw_dat_mon:
	rcall LCD_DrawStringPM
	pop frg_color
	pop bkg_color
	pop ZL
	pop ZH

	sbrs refresh, 4
	rjmp drw_dat_end

	andi refresh, 0b11101111
	ldi tmp, 0x05+(0x08*7)
	mov lcd_x, tmp
	adiw ZL, 0x01
	ld tmp, Z
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_year
	cpi mode_tmp, 0x06
	brne drw_dat_year
	rcall Exch_bkg_frg
drw_dat_year:
	rcall LCD_DrawBCD
	sbiw ZL, 0x01
	ld tmp, Z
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color
drw_dat_end:
	pop tmp1
	pop tmp
	pop ZL
	pop ZH
	ret
;--------------------
LCD_DrawDayOfWeek:
	push tmp1
	LASZ day_of_week 	; ������ ���� ������
	ld tmp, Z

	clr tmp1
	LAPZ week_day_center_coo
	add ZL, tmp
	adc ZH, tmp1
	lpm tmp1, Z

	mov lcd_x, tmp1
	ldi tmp1, 60
	mov lcd_y, tmp1

	LAPZ week_day_table
	lsl tmp
	add ZL, tmp
	clr tmp
	adc ZH, tmp
	lpm tmp, Z+
	lpm tmp1, Z
	mov ZL, tmp
	mov ZH, tmp1
	rcall LCD_DrawStringPM
	pop tmp1
	ret
;--------------------
.include "Sie_c60.inc"	; Siemens C60 routines

;-------- ������

.include "CP866.inc"	; 8x8 font

month_len:
	.db 0x32,0x29,0x32,0x31,0x32,0x31,0x32,0x32,0x31,0x32,0x31,0x32

; ���������� ���������
month_names:
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00
	.db "���",0x00

week_day_names:
mon:	.db "�����������",0x00
tue:	.db "�������",0x00
wed:	.db "�����",0x00
thu:	.db "�������",0x00
fri:	.db "�������",0x00
sat:	.db "�������",0x00
sun:	.db "�����������",0x00

week_day_table:
	.dw mon<<1, tue<<1, wed<<1, thu<<1, fri<<1, sat<<1, sun<<1

week_day_center_coo:
	.db 6, 22, 30, 22, 22, 22, 6, 0x00

corr_table:
	.dw hour, minute, second, day, day_of_week, month, year

corr_max_value:
	.dw 0x24, 0x60, 0x60, 0x00, 0x07, 0x12, 0x9999

sie_c60_init:
	.db	0x80,0x04,0x8A,0x54,0x45,0x52,0x43,0x02,0x0A,0x15,0x1F,0x28,0x30,0x37,0x3F,0x47,0x4C,0x54,0x65,0x75,0x80,0x85,0x00,0x03,0x05,0x07,0x09,0x0B,0x0D,0x0F,0x00,0x03,0x05,0x07,0x09,0x0B,0x0D,0x0F,0x00,0x05,0x0B,0x0F
;	.db 7,15,


;-------- ����� cseg

.dseg ; ������� ������ ���
.org 0x100
; ����-����� (BCD)
	dsecond: .db 0x00
	second: .db 0x00
	minute: .db 0x00
	hour: .db 0x00
	day: .db 0x00
	month: .db 0x00
	year: .dw 0x00
	day_of_week: .db 0x00

	tim_ovf_val: .db 0x00	; ������������ 5�� ��������� (����� ������ �������������)

	; �������� ��������� ���� (����� ������ �������������)
	corr_period: .dd 0x00000000	; ������, �� ���������� �������� ������������ ������������� (������� ���� �������)
	corr_per_cnt: .dd 0x00000000
	corr_value: .dw 0x0000		; �������������� �������� (BCD) lsb - ������� ���� ������, msb - �������, ������� ��� lsb - ���� ��������� (+/-)

	sec_duration: .db 0x00	; ������������ ������� (������ �������������)
	sec_cnt: .db 0x00

;-------- ����� dseg

.eseg ; ������� eeprom

sec_dur_eep: .db 0x14

;-------- ����� eseg
