; ������� � �����������

;------- ���������
.equ num_mode = 0x02
.equ sec_part = 8
.equ OCR2A_val = 128
.equ TimCntVal = 32
;-------

;------- �����������
.def lcd_X = r2	; ������� ����������
.def lcd_Y = r3
.def bkg_color = r4 ; ����� ���� � ������
.def frg_color = r5
.def lcd_mx = r6	; ��������� ���������������
.def lcd_my = r7

.def kbd = r8	; ������� ����� ������� ������
.def kbd_prev = r12	; ������� ����� ������� ������ ����������� �����
.def kbd_press = r13 ; ������� ������ (�� 1 � 0)
.def kbd_release = r14 ; ���������� ������ (�� 1 � 0)

.def sec_part_cnt = r10

.def led_timer=r9	; ������ ��������� (0.1 ��������� ����������)
.def mode=r19	; ����� ������: 0 - ���� (����������� ����-�������), 1 - ��������� ����, �������,
				; ������ � ������ ��������� �����, 2 - ���������� �� �������� ���������, 3 - ������
.def mode_tmp=r24 ; ��� ������ 1 - ����� �������� ������� ������������� �������� (���, ������, ������� � �.�.)
				  ; 0 - ���, 1 - ������, 2 - �������, 3 - �����, 4 - ���� ������, 5 - �����, 6 - ��� (���� ���)

.def tmp=r16	; Temp
.def tmp1=r17
.def tmp2=r18
;-------

;------- �������
.macro CS_LOW
	cbi PORTB, 1
	nop
.endm
.macro CS_HIGH
	sbi PORTB, 1
	nop
.endm
.macro LED_ON
	sbi PORTC, 1
	nop
.endm
.macro LED_OFF
	cbi PORTC, 1
	nop
.endm
.macro CMD_SET
	cbi PORTB, 0
	nop
.endm
.macro DATA_SET
	sbi PORTB, 0
	nop
.endm
.macro LCD_RESET_LOW
	cbi PORTC, 0
	nop
.endm
.macro LCD_RESET_HIGH
	sbi PORTC, 0
	nop
.endm
.macro LAPZ
	ldi ZH, high(@0 << 1)
	ldi ZL, low(@0 << 1)
.endm
.macro LAPX
	ldi XH, high(@0 << 1)
	ldi XL, low(@0 << 1)
.endm
.macro LAPY
	ldi YH, high(@0 << 1)
	ldi YL, low(@0 << 1)
.endm
.macro LASZ
	ldi ZH, high(@0)
	ldi ZL, low(@0)
.endm
.macro LASX
	ldi XH, high(@0)
	ldi XL, low(@0)
.endm
.macro LASY
	ldi YH, high(@0)
	ldi YL, low(@0)
.endm
;-------