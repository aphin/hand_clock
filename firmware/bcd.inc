; Подпрограммы BCD
BCD_Add:
; in: Z - указывает на BCD число в памяти
;     tmp - второе слагаемое (BCD)
; out: число по адресу Z
; GPIOR0(bit0) - BCD carry
	
	push tmp1
	push tmp
	push r20

	cbi GPIOR0, 0
	ld tmp1, Z
	
;--- Взято из аппнотов атмела	
	ldi r20,6	;value to be added later
	add tmp1,tmp	;add the numbers binary
	cbi GPIOR0,0		;clear BCD carry
	brcc add_0		;if carry not clear
	sbi GPIOR0,0		;    set BCD carry
add_0:	
	brhs add_1		;if half carry not set
	add tmp1,r20	;    add 6 to LSD
	brhs add_2		;    if half carry not set (LSD <= 9)
	subi tmp1,6		;        restore value
	rjmp add_2		;else
add_1:	
	add tmp1,r20	;    add 6 to LSD
add_2:	
	brcc add_2a
	sbi GPIOR0,0	
add_2a:	
	swap r20
	add	tmp1,r20	;add 6 to MSD
	brcs add_4		;if carry not set (MSD <= 9)
	sbis GPIOR0, 0		;    if previous carry not set
	subi tmp1, 0x60	;	restore value
add_3:	
	rjmp bcd_end		;else
add_4:
	sbi GPIOR0, 0		;    set BCD carry
;---
bcd_end:
	st Z, tmp1

	pop r20
	pop tmp
	pop tmp1	
	ret
;-------------------
BCD_Inc:
; in: Z - указывает на BCD число в памяти
; out: число по адресу Z
	push tmp
	ldi tmp, 0x01
	rcall BCD_Add
	pop tmp
	ret

BCD_Dec:
; in: Z - BCD число
; out: число по адресу Z. ! флаг переноса выставляется не правильно
	ldi tmp, 0x99	; tmp не сохраняется в стеке ! (оптимизация)
	rcall BCD_Add
	ret

BCD2Bin:
; in: Z - BCD число
; out: tmp - бинарное число
	push tmp1

	ldi tmp1, 0x0A
	ld tmp, Z
	swap tmp
	andi tmp, 0x0F
	mul tmp, tmp1
	ld tmp, Z
	andi tmp, 0x0F
	add tmp, r0

	pop tmp1
	ret
