; ������������ ��� ������ � �����-��������

;---------------------
CheckLeapYear:
; ��������� ������� ��� �� "������������" � ���������� ��� ������������� ����� �������
	push tmp
	push tmp1
	push r20
	push ZL
	push ZH

	LASZ year
	rcall BCD2bin
	mov tmp1, tmp
	adiw ZL, 0x01
	rcall BCD2bin
	LASZ month_len_ram
	adiw ZL, 0x01

	mov r20, tmp	; (year % 4) == 0 ???
	andi r20, 0x03
	cpi r20, 0x00
	brne ly_no_corr
	cpi tmp, 0x00	; (year % 100) != 0 ???
	brne ly_correct
	andi tmp1, 0x03
	cpi tmp1, 0x00	; (year % 400) == 0 ???
	brne ly_no_corr
	cpi tmp, 0x00
	brne ly_no_corr
ly_correct:
	ldi tmp, 0x30
	rjmp ly_end
ly_no_corr:
	ldi tmp, 0x29
ly_end:
	st Z, tmp

	pop ZH
	pop ZL
	pop r20
	pop tmp1	
	pop tmp
	ret

;---------------------
Time_Date_Inc:
	push ZH
	push ZL
	push tmp

	LASZ dsecond
	rcall BCD_Inc	; ���� ������� (�������� ���������� sec_part)
	ld tmp, Z
	cpi tmp, sec_part
	breq tdi_cnt1
	rjmp tdi_end
tdi_cnt1:

; ������ �������� �� 1 ���� ������� TC2 (��������, �.�. �� ���� "���������" ������� ������� 32767 ������ � ������� ������ 32768)
; �� ����������������, �.�. � ���� ����� ���� ��������� "����" ���� ���� ������ ��������� 3 �����
; ����� �������� ������� �������� �������� ������� ��������� � �������� �������� 0�01, � ��������� ��� ���� � ������� ������� ��� �������� 0�01 ������
; 0�02

tdi_fix_w:
	lds tmp, TCNT2
	cpi tmp, 0x01
	brlo tdi_fix_w
	ldi tmp, 0x02	; ���������� � ������� 0�02, (���������� ����-�������� ������ 3 ����� �������, �� �� �������� ���� 2, ����� ������� ������ �������� �� ����)
	sts TCNT2, tmp
tdi_fix_w1:
	lds tmp, ASSR
	sbrc tmp, TCN2UB
	rjmp tdi_fix_w1
; ---

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
	LASZ day_of_week
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
	push tmp
	rcall TimeDate_mlen_calc
	pop tmp
	cp tmp, tmp1
	pop tmp1
	brne tdi_end
	ldi tmp, 0x01
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

TimeDate_mlen_calc:
	push ZH
	push ZL
	ldi ZH, high(month)
	ldi ZL, low(month)
	ld tmp, Z	; � tmp - ����� ������ � ������� BCD
	sbrc tmp, 4
	subi tmp, 6	; � tmp ����� ������ � binary
	ldi ZH, high(month_len_ram)
	ldi ZL, low(month_len_ram)
	add ZL, tmp
	ldi tmp, 0x00
	adc ZH, tmp
	ld tmp1, Z
	pop ZL
	pop ZH
	ret
