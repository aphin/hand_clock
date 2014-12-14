; �������� ��� �������� ����� �� ATMEGA48PA, ������� Siemens A70, 6 ������
; TODO
; 1. �������� �������������� ������ � ��������� �� ���� ������

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
	
main:
	sbrc wflags, 3	; ���� ���� �������� - � ��� �� ������ (���� ��� ��� �������)
	rjmp m_no_sleep
	
	sleep	; �������� ��� :-)

; ���� ���������� TC2 ��� � ���-����� �� RTC
	ldi tmp, 0x00
	sts OCR2B, tmp
wtr:
	lds tmp, ASSR
	sbrc tmp, OCR2BUB
	rjmp wtr

m_no_sleep:
	sbrs wflags, 4	; ���� ���������� RTC ��������� - ���������� (�������� �����, �.�. ���������� �� ���� ��� ��������� �����)
	rjmp main
	andi wflags, 0b11101111

; ��������� �������
m_tdr:
	sbrs refresh, 6 ; ������ �������
	rjmp m_music
	sbis GPIOR0, 3
	rjmp m_music
	LASZ timer_sec
	ld tmp, Z+
	cpi tmp, 0x00
	brne m_tdr1
	ld tmp, Z
	cpi tmp, 0x00
	breq m_tdr_stop
m_tdr1:
	sbiw ZL, 0x01
;	ldi tmp, 0x99
;	rcall BCD_Add	; BCD_Dec
	rcall BCD_Dec
	ld tmp, Z
	cpi tmp, 0x60
	brlo m_tdr_ref
	ldi tmp, 0x59
	st Z+, tmp
;	ldi tmp, 0x99
;	rcall BCD_Add	; BCD_Dec
	rcall BCD_Dec
	ld tmp, Z
m_tdr_ref:
	ori refresh, 0b00100000
	rjmp m_music
m_tdr_stop:
	ldi tmp, 0x00
	st Z, tmp
	andi refresh, 0b10111111
	ori refresh, 0b00100000

; ������ ������
	LAPZ music
	rcall play_music

m_music:
; ��������� ������
	sbrs wflags, 5
	rjmp m_alarm
	sbrc wflags, 3
	rjmp m_alarm
	LASZ music_pointer_l
	ld tmp, Z+
	ld tmp1, Z
	mov ZL, tmp
	mov ZH, tmp1
	lpm tmp, Z+
	lpm snd_delay_l, Z+
	cpi snd_delay_l, 0x00
	brne music_cont
	andi wflags, 0b11011111	; ������ �����������
	rjmp m_alarm
music_cont:
	cpi tmp, 0x00
	breq music_pause
	rcall sound_freq  ; ������ �����
	beep_on
	rjmp music_out
music_pause: ; ������ �����
	beep_off
	ori wflags, 0b00001000	; ���� ��������, �� ������ ��������� �����
music_out:
	mov tmp, ZH	; ��������� �������� ��������� � ������
	mov tmp1, ZL
	LASZ music_pointer_l
	st Z+, tmp1
	st Z, tmp
; ��������� ����������
m_alarm:
	sbrs wflags, 6
	rjmp m_cont
	sbis GPIOR0, 3	; ��������� �������� ������ �������
	rjmp m_cont
	LASZ bud_min
	ldi YL, low(minute)
	ldi YH, high(minute)
	ld tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1
	brne m_cont
	ld tmp, Z
	ld tmp1, Y
	cp tmp, tmp1
	brne m_cont
; ���� ���������� - ������ ������, � ��� ����� ������ :-)
	sbrc wflags, 5
	rjmp m_cont
	LAPZ music
	rcall play_music

m_cont:					; ��������� �������
	cpi mode, 0x00
	brne m_mode1

; ����� 0 - ������ ����, ��������� 5 ������ �� �������
	sbis GPIOR0, 3	; ��������� ��������� ������ �������
	rjmp kbd_hand

m_draw_dt:
	ldi lcd_x, 3
	ldi lcd_y, 2
	rcall LCD_DrawTime
	rcall LCD_DrawDate
	rcall LCD_DrawBattery
	ldi lcd_x, 3
	ldi lcd_y, 2

	rjmp kbd_hand

; ����� 1 - ������ ����-�����, ��������� ��������, ������ � ���������� 0.1 ���
m_mode1:
	cpi mode, 0x01
	brne m_mode2
	sbis GPIOR0, 2
	rjmp kbd_hand
	rjmp m_draw_dt

m_mode2:				
; ����� 2 - ����� �������������� ������
	sbrs refresh, 5	; ��� 5 ��������� �� ������������� ���������� �������
	rjmp kbd_hand
	andi refresh, 0b11011111
	rcall LCD_DrawTimer

kbd_hand:
	mov tmp, kbd_press
	ori tmp, 0b11000000
	cpi tmp, 0xFF
	brne kbd_hcont
	rjmp main

kbd_hcont:
; ���� ��� ������� �� ������
	ldi snd_delay_l, 5
	beep_on
; ����������� ��� ������ �������
	cpi mode, 0x00
	brne m_kbd_mode1
; ���������� ������ ������ 0
	sbrc kbd_press, 3
	rjmp nx_b
	LED_ON
	ldi tmp, 40
	mov led_timer, tmp
nx_b:
	sbrc kbd_press, 5
	rjmp nx_b1
	inc mode
	rcall LCD_Clear
	ori refresh, 0b00011111
	LED_ON
nx_b1:
	sbrc kbd_press, 1	; �������� ����� �������
	rjmp nx_b2
	ldi mode, 0x02
nx_b1_b:				; ��� ������� � ����������
	rcall LCD_Clear
	ldi lcd_x, 26
	ldi lcd_y, 0
	scale1x
	cpi mode, 0x02
	brne nx_b1_drb
	LAPZ tim_str
	rjmp nx_b1_dr
nx_b1_drb:
	LAPZ bud_str
	ldi lcd_x, 15
nx_b1_dr:
	rcall LCD_DrawStringPM
	ori refresh, 0b00100000
nx_b2:
	sbrc kbd_press, 0	; �������� ����� ����������
	rjmp nx_b3
	ldi mode, 0x03
	rjmp nx_b1_b
nx_b3:
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
;	ldi tmp, 0x99
;	rcall BCD_Add	; ���������� BCD_Dec
	rcall BCD_Dec
val_check:
	ld tmp, Z	; � tmp ����� ����� �����������
	cpi mode_tmp, 0x02
	breq sec_corr
	cpi mode_tmp, 0x03
	breq day_corr
	cpi mode_tmp, 0x06
	breq no_corr
hr_mn_mo:
; ��� �����, ����� � ������
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
	clr sec_part_cnt ; �������� ������� ��������� 0.1 ���
	rjmp no_corr
day_corr:
; � ����� ����� ����������������� ������� �����	
	push tmp
	rcall TimeDate_mlen_calc
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
; ���������� ������ ������ 2 (������) � 3 (���������)
	sbrc kbd_press, 1
	rjmp nx_b_m2
	cpi mode, 0x02
	brne kb1_m2_bud
nx_b0_m2_out:
	clr mode
	rcall LCD_Clear
	ori refresh, 0b00011111
	rjmp main
mode2_out:
	ori refresh, 0b00100000
	rjmp main
kb1_m2_bud:	; ��������� ����� ����������
	LASZ bud_min
	rcall BCD_Inc
	rjmp nx_b4_m2_cnt
nx_b_m2:
	sbrc kbd_press, 3	; ��������� � ������ �������
	rjmp nx_b1_m2
	LED_ON
	ldi tmp, 40
	mov led_timer, tmp
nx_b1_m2:
	sbrc kbd_press, 0 ; �����/���� �������
	rjmp nx_b2_m2
	cpi mode, 0x03	; ��� ����� �� ������ ����������, �� ���� �������� ���������, �� ���������/���������� ����������
	breq nx_b1_check
	ldi tmp, 0b01000000
	eor refresh, tmp
	rjmp main
nx_b1_check:
	tst led_timer	; ���� ��������� ��������� (led_timer = 0) �� ����� �� ������ ����������
	breq nx_b0_m2_out
	ldi tmp, 0b01000000
	eor wflags, tmp	; � ��������� ������ ���/���� ����������
	ori refresh, 0b00100000
	rjmp main
nx_b2_m2:
	sbrc kbd_press, 4 ; ��������� ����� (������ ���� ������ ����������)
	rjmp nx_b3_m2
	cpi mode, 0x02
	brne nx_b2_m2_bud
	sbrc refresh, 6
	rjmp main
	LASZ timer_min
	rcall BCD_Inc
	rjmp mode2_out
nx_b2_m2_bud:	; ��������� ����� ��� ����������
	LASZ bud_hr
	rcall BCD_Inc
	ld tmp, Z
	cpi tmp, 0x24
	brne mode2_out
	ldi tmp, 0x00
	st Z, tmp
	rjmp mode2_out 
nx_b3_m2:
	sbrc kbd_press, 5 ; ��������� ����� (���� ������ ���� ������ ����������)
	rjmp nx_b4_m2
	cpi mode, 0x02
	brne nx_b3_m2_bud
	sbrc refresh, 6
	rjmp main
	LASZ timer_min
;	ldi tmp, 0x99
;	rcall BCD_Add
	rcall BCD_Dec
	rjmp mode2_out
nx_b3_m2_bud:	; ��������� ����� ��� ����������
	LASZ bud_hr
;	ldi tmp, 0x99
;	rcall BCD_Add
	rcall BCD_Dec
	ld tmp, Z
	cpi tmp, 0x99
	brne mode2_out
	ldi tmp, 0x23
	st Z, tmp
	rjmp mode2_out
nx_b4_m2:
	sbrc kbd_press, 2 ; ��������� ������ (��� �� ���� ������ ����������)
	rjmp main
	cpi mode, 0x02
	brne nx_b4_m2_bud
	sbrc refresh, 6
	rjmp main
	LASZ timer_sec
	rcall BCD_Inc
nx_b4_m2_cnt:
	ld tmp, Z
	cpi tmp, 0x60
	brne b4_m2_end
	ldi tmp, 0x00
	st Z, tmp
b4_m2_end:	
	rjmp mode2_out
nx_b4_m2_bud:	; ��������� ����� ����������
	LASZ bud_min
;	ldi tmp, 0x99
;	rcall BCD_Add
	rcall BCD_Dec
	ld tmp, Z
	cpi tmp, 0x99
	brne b4_m2_end
	ldi tmp, 0x59
	st Z, tmp
	rjmp mode2_out
	
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
AnalogDC:
EE_RDY:
AnalogCMP:
TWI:
SPM_RDY:
	reti

USART_TX:	; ������������ ��� ��������� �����. ��� ������ �������� ���������, � ���� ��������� ��� ���������� - �������� ����� ��������
	push tmp
	ldi tmp, 0x00
	sts UDR0, tmp
	pop tmp
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

T2_COMPA:		; ���������� ���������� �� ������� RTC, �������� ������ 5 ��
	push tmp
	in tmp, SREG
	push tmp
	push tmp1

	push ZH
	push ZL
	push YH
	push YL

	ori wflags, 0b00010000	

	in tmp, GPIOR0
	andi tmp, 0b00000011
	out GPIOR0, tmp			; ���������� ����� ��������� �������

	rcall KBD_Check ; ���� ������
	
	ldi tmp, TimCntVal
	inc sec_part_cnt
	cp sec_part_cnt, tmp
	brne t2_end

; ������ 1/8 �������
	sbi GPIOR0, 2	; ���������� ����
	
	rcall Time_Date_Inc	; ��������� ����-�������

	clr sec_part_cnt	; �������� �������
; ������������� ������� (���)
; ���������� ������� ����� � ������� ���
	LAPZ w_time_corr
	ldi YH, high(dsecond)
	ldi YL, low(dsecond)
	lpm tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1	; ���������� ���� ������
	brne t2_no_tcor
	lpm tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1	; ���������� �������	
	brne t2_no_tcor
	lpm tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1	; ���������� ������
	brne t2_no_tcor
	lpm tmp, Z
	ld tmp1, Y
	cp tmp, tmp1	; ���������� ����
	brne t2_no_tcor
; ���� �������� ������ ���� ��� ��������� ���� ��������� "�����", � ��������� ��� �� �������� (��� 7 �������� refresh = 0) - ��� ������ ���� ������ ���������
	sbrc refresh, 7
	rjmp t2_no_tcor_r
	sbiw YL, 3
	ldi tmp, 0x00	; ������������� ����� 00:00:00.0
	st Y+, tmp
	st Y+, tmp
	st Y+, tmp
	st Y, tmp
	ori refresh, 0b10000000
	rjmp t2_no_tcor
t2_no_tcor_r:
	andi refresh, 0b01111111
; ����������, � ����� ������ �������� ����
t2_no_tcor:
	cpi mode, 0x00
	brne tc2_mode1
; ����� 0 - ���������� ����������
	tst led_timer		; ������ � ����������
	breq t2_end
	dec led_timer
	brne t2_end
	LED_OFF
	rjmp t2_end

tc2_mode1:
; ����� 1 - ��������� ����, �������, �������������
	cpi mode, 0x01
	brne tc2_mode2

	rjmp t2_end

tc2_mode2:
; ����� 2 - ������
	tst led_timer	; ���������
	breq t2_end
	dec led_timer
	brne t2_end
	LED_OFF

t2_end:
	cpi snd_delay_l, 0x00	; ���������� �����
	breq t2_out
t2_snd_cont:
	dec snd_delay_l
	brne t2_out
t2_no_sound:
	beep_off
t2_out:
	pop YL
	pop YH
	pop ZL
	pop ZH
	pop tmp1
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
Send_SPI:
SPI_Send:
	push tmp
	out SPDR, tmp
spi_wait:
	in tmp, SPSR
	sbrs tmp, SPIF
	rjmp spi_wait
	pop tmp
	ret	
;--------------------
.include "bcd.inc"
.include "Sie_A70.inc"	; Siemens A70 routines
.include "sound.inc" ; ����
.include "time_date.inc" ; ��� ���� � �������

;-------- ������

.include "symbols.inc"	; 8x8 font
.include "data.inc"


;-------- ����� cseg

.dseg ; ������� ������ ���
.org 0x100

.include "ram.inc"

;-------- ����� dseg
