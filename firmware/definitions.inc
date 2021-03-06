; ������� � �����������

; �������� GPIORx
; GPIOR0.0 - ���� �������� BCD
; GPIOR0.1 - ������������ ��� ��������������� ���� ��� ������ ����������
; GPIOR0.2 - ��������������� � 1 ������ 1/8 ���� �������
; GPIOR0.3 - ...������ �������
; GPIOR0.4 - ...������
; GPIOR0.5 - ...���
; GPIOR0.6 - ...����
; GPIOR0.7 - ���� 0 - ������� ���������, 1 - ���������

;------- ���������
.equ num_mode = 0x02
.equ sec_part = 8
.equ OCR2A_val = 127
.equ TimCntVal = 32
;.equ KbdDelay = 16 ; ������ � 1/8 ��������� ����������, �� ���������� �������� ������ ��������� ������� ���������
; ����������� ��� ��� ������
; 4-� ������
.equ o4C = 241	; ��
.equ o4Cd = 225	; ��-����
.equ o4D = 211	; ��
.equ o4Dd = 201	; ��-����
.equ o4E = 190	; ��
.equ o4F = 180	; ��
.equ o4Fd = 170	; ��-����
.equ o4G = 160	; ����
.equ o4Gd = 151	; ����-����
.equ o4A = 142	; ��
.equ o4Ad = 133	; ��-����
.equ o4H = 125	; ��
; 5-� ������
.equ o5C = 118	; ��
.equ o5Cd = 111	; ��-����
.equ o5D = 105	; ��
.equ o5Dd = 100	; ��-����
.equ o5E = 94	; ��
.equ o5F = 89	; ��
.equ o5Fd = 84	; ��-����
.equ o5G = 78	; ����
.equ o5Gd = 73	; ����-����
.equ o5A = 69	; ��
.equ o5Ad = 63	; ��-����
.equ o5H = 60	; ��

;������������
.equ T1 = 208	; ������� (����)
.equ T1_2 = T1/2	; 1/2
.equ T1_4 = T1/4	; 1/4
.equ T1_8 = T1/8	; 1/8
.equ T1_16 = T1/16	; 1/16

;------- �����������
; r0,r1 - ������������ ��� ���������� mul
; r2, r3, r4, r5, r6 - ��������

;.def kbd_delay_cnt = r7 ; ������� �������� ������� ������

.def kbd = r8	; ������� ����� ������� ������
.def led_timer=r9	; ������ ��������� (1/8 ��������� ����������)
.def sec_part_cnt = r10 ; ������� ����� �������

;.def kbd_delay_press = r11 ; ������� ����� ������, ������� ����� ������� Kbd_Delay
.def kbd_prev = r12	; ������� ����� ������� ������ ����������� �����
.def kbd_press = r13 ; ������� ������ (�� 1 � 0)
.def kbd_release = r14 ; ���������� ������ (�� 0 � 1)

; r15 - ��������

.def tmp=r16	; Temp
.def tmp1=r17
.def lcd_y=r18	; ���������� Y

.def mode=r19	; ����� ������: 0 - ���� (����������� ����-�������), 1 - ��������� ����, �������,
				; 2 - ������, 3 - ���������

; r20 - ������������ � ������������� ��� �������
.def lcd_x = r21	; ���������� X
.def wflags = r22	; ������ �����: 
; 0 - ��������������� x2, 
; 1 - ����� ������� (��� 7-�� �����������)
; 2 - ���� ������������ ��� �������������� ���������
; 3 - ���� ����������� �����, ������������ ��� �������� � ���. ����� �������� ���� - ���� �� ������ � ���.
; 4 - ���� ������������ ���������� RTC
; 5 - ���� ������������ ������
; 6 - ���� ���������� 1-�������, 0-��������

.def refresh = r23	; ������� � ������� ����������
; ����:
; 0 - ���� �������� ������
; 1 - ����
; 2 - �����/���� ������
; 3 - �����
; 4 - ���
; 5 - ���������� �������/����������
; 6 - ������ �������(1)/����������(0)
; 7 - ���� ��������� ���
; �.�. ��������� ���� �� ������� ��� ��� � �������, �� ������� ����������� ������ ���� � ���
.def mode_tmp=r24 ; ��� ������ 1 - ����� �������� ������� ������������� �������� (���, ������, ������� � �.�.)
				  ; 0 - ���, 1 - ������, 2 - �������, 3 - �����, 4 - ���� ������, 5 - �����, 6 - ��� (���� ���)
				  ; ���� �� �������� � ��������� ����� ����� �������� ����-������� ����� ����������

.def snd_delay_l = r25 ; ������������ ��������� ������� � 5�� ����������

; r26, r27 - X (�� ������������)
; r28, r29 - Y (������������ � ���)
; r30, r31 - Z (������������ �����)
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
.macro LASZ
	ldi ZH, high(@0)
	ldi ZL, low(@0)
.endm
.macro INVCOL
	sbi GPIOR0, 7
.endm
.macro NORMCOL
	cbi GPIOR0, 7
.endm
.macro beep_off
	rcall sound_off
.endm
.macro beep_on
	rcall sound_on
.endm
.macro scale2x
	ori wflags, 0x01
.endm
.macro scale1x
	andi wflags, 0xFE
.endm
;-------


