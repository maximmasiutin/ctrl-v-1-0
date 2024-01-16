CODE	segment
	assume 	cs:CODE,ds:CODE,es:CODE
	org 100h
START:	

Pressed:
        jmp	INSTALL
int9_0:
        call    RealInt9
        db      0EAh
old9o_0 dw      0
old9s_0 dw      0
	
int9_1:
        call    RealInt9
        db      0EAh
old9o_1 dw      0
old9s_1 dw      0


RealInt9:
	cli
	pushf
        push    ax
	push	bx
	push	ds

	push	cs
	pop	ds

	lea	bx,pressed
	
	cmp	byte ptr ds:Working,1
	jnz	NotWorking
	jmp	CL_Exit

NotWorking:
	in	al,60h

	cmp	byte ptr ds:[bx],1
	jz	Ctrl
	jmp	NotCtrlAlt
Ctrl:
	cmp	byte ptr ds:[bx+2],1
	jz	CtrlAlt
	jmp	NotCtrlAlt


CtrlAlt:

	cmp	al,25	; "P"
	jnz	NotS


	mov	al,20h
	out	20h,al

	xor	ax,ax
	mov	ds,ax
	mov	bx,9*4

	push	word ptr ds:[bx]
	push	word ptr ds:[bx+2]

	mov	ax,word ptr cs:old9o_0
	mov	word ptr ds:[bx],ax
	mov	ax,word ptr cs:old9s_0
	mov	word ptr ds:[bx+2],ax

	xor	ax,ax
	pushf
	call 	dword ptr cs:old16o

	pop	word ptr ds:[bx+2]
	pop	word ptr ds:[bx]


	pop	ds
	pop	bx
	pop	ax
	popf
	pop	word ptr cs:UseMe
	iret
		

NotS:
	cmp	al,32	; "D"
	jnz	NotD

ComputerReset:
	db	0EAh
	dw	0FFF0h,0F000h

NotD:
	cmp	al,46	; "C"
	jnz	NotC
	mov	word ptr ds:CutNo_Hi,'00'
	jmp	short CL_Exit
	

NotC:

NotCtrlAlt:
	cmp	al,56	; Alt
	jnz	NotAlt
	mov	byte ptr ds:[bx+2],1
	jmp	short CL_EXIT

NotAlt:
	cmp	al,55	; PrtSrc
	jz	BREAK
	cmp	al,29	; CTRL
	jnz	CLEAR
	mov	byte ptr ds:[bx],1
	jmp	short CL_EXIT
BREAK:			
	cmp	byte ptr ds:[bx],1
	jnz	CL_EXIT
;
	mov	word ptr ds:[bx],100h
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr ds:[8*4]
	mov	word ptr cs:old08o,ax
	mov	ax,word ptr ds:[8*4+2]
	mov	word ptr cs:old08s,ax
	
	lea	ax,Int08
	mov	word ptr ds:[8*4],ax
	mov	word ptr ds:[8*4+2],cs
	jmp	short CL_EXIT

;
	
CLEAR:

	mov	word ptr ds:[bx],0
	mov	byte ptr ds:[bx+2],0

CL_EXIT:
	pop	ds
	pop	bx
	pop     ax
	popf
        ret

Working	db	0
EnoughCut dw	0
FourPanel_WRITE_FILE:
	mov	word ptr FourPanel_WORDS,cx
	
	mov	ax,word ptr CutNo_Hi
	mov	cx,3
IncCutNo3:
	call	IncCutNo
	loop	IncCutNo3	
	xchg	word ptr CutNo_Hi,ax
	mov	word ptr EnoughCut,ax

	mov	ax,0A000h
	mov	ds,ax
	
FourPanel_LOOP:
	push	ds
	push	cs
	pop	ds



	mov	ax,3C00h 	;	FourPanel begin;
	lea	dx,fname
	xor	cx,cx
	int	21h             ; Создаем файл
	mov	bx,ax
	mov	cx,offset FourPanel_LOADER_END-offset FourPanel_FBeg
	lea	dx,FourPanel_FBeg
	mov	ah,40h
	int	21h            ; Пишем в файл загрузчик
	pop	ds


        mov     dx,3CEh    ;  │
        mov     al,5       ;  │
        out     dx,al      ;  │ Установим режим чтения
        inc     dx         ;  │
        mov     al,0       ;  │
        out     dx,al      ;  │
        dec	dx         ;  │
        mov     al,4       ;  │ Установим нужную битовую карту
        out     dx,al      ;  │
        inc     dx         ;  │
        mov     al,cs:PANEL_NUM ;<───── Карта
        out     dx,al      ;  │

        mov     ah,40h
        mov     cx,word ptr cs:FourPanel_WORDS
        shl     cx,1
	cwd
	int	21h

       	mov	ah,3Eh
	int	21h		;	FourPanel end;

	mov	ax,word ptr cs:EnoughCut
        cmp     word ptr cs:CutNo_Hi,ax
	jz      EXIT_FourPanel_LOOP
	push	ds
	push	cs
	pop	ds
	call	IncCutNo
	shl	FourPanel_LOADER_PANEL_NUM,1
	inc	PANEL_NUM
	pop	ds
        jmp     short FourPanel_LOOP

EXIT_FourPanel_LOOP:
        jmp	EXIT_PROCESSING

SinglePanel_WRITE_FILE:
	mov	ah,3Ch 		;	begin
	lea	dx,fname
	xor	cx,cx
	int	21h
	mov	bx,ax
	mov	cx,offset SinglePanel_data-offset SinglePanel_FBeg
	lea	dx,SinglePanel_FBeg
	mov	ah,40h
	mov     word ptr ADDRESS,si
	mov	word ptr SinglePanel_WORDS,di
	int	21h
	shl	di,1
	mov	ax,si		
	mov	ds,ax
	mov	cx,di
	mov	ah,40h
	cwd
	int	21h
	mov	ah,3Eh
	int	21h		;	 end;
	jmp	EXIT_PROCESSING

SinglePanel_FBeg:
	cli	;│ Настроим 
	cld     ;│  флаги

	push	cs	;│				│  Настроим
	pop	ds	;│				│ сегментные
	db	0B8h	;│ Это команда mov ax,____	│  регистры
ADDRESS dw	0	;│ Это резерв для '____'	│   ES  DS
	mov	es,ax	;│				│

	db	0B9h	;│<── Это команда mov cx,____	│ Помещаем в CX
SinglePanel_WORDS dw	0	;│<── Это резерв для '____'	│  кол-во слов
	xor	di,di
	mov	si,offset SinglePanel_data-offset SinglePanel_Fbeg+100h
	rep	movsw
	sti
	int	20h	
SinglePanel_data:


FourPanel_FBeg:

        cli
	cld

	push	cs
	pop	ds

	mov	ax,0A000h
	mov	es,ax

        mov     dx,3CEh  ;  ─────────────────
        mov     al,5     ; │                 │
        out     dx,al    ; │ Установим режим │
        inc     dx       ; │     записи      │
        xor     al,al    ; │                 │
        out     dx,al    ;  ─────────────────

        mov     dx,3C4h
        mov     al,2
        out     dx,al
        inc     dx
	db	0B0h		;│ Это  ─  mov al,EGA_..._PANEL_NUM
FourPanel_LOADER_PANEL_NUM db 1	;│
        out     dx,al		;│ Установим цветовую плоскость
	
	xor	di,di
	mov	si,offset FourPanel_LOADER_END-offset FourPanel_FBeg+100h
	db	0B9h	;│<── Это команда mov cx,____	│ Помещаем в CX
FourPanel_WORDS dw	0	;│<── Это резерв для '____'	│  кол-во слов

	rep	movsw

	sti
	int	20h	
FourPanel_LOADER_END:


EGA_D_Fbeg:


        cli
	cld

	nop
	

	push	cs
	pop	ds

	mov	ax,0A000h
	mov	es,ax
        mov	si,offset EGA_D_LOADER_END-offset EGA_D_FBeg+100h
        mov	ah,1

EGA_D_Floop:
        mov     dx,3CEh  ;  ─────────────────
        mov     al,5     ; │                 │
        out     dx,al    ; │ Установим режим │
        inc     dx       ; │     записи      │
        xor     al,al    ; │                 │
        out     dx,al    ;  ─────────────────

        mov     dx,3C4h
        mov     al,2
        out     dx,al
        inc     dx
        mov     al,ah
        out     dx,al
	xor	di,di
        mov     cx,0FA0h

	rep	movsw
        shl	ah,1
        cmp	ah,10000b
        jnz     EGA_D_Floop


	sti
	int	20h	

EGA_D_LOADER_END:


EGA_D_Write_File:
	
	mov	ah,3Ch 		;	FourPanel begin;
	lea	dx,fname
	xor	cx,cx
	int	21h             ; Создаем файл
	mov	bx,ax
	mov	cx,offset EGA_D_LOADER_END-offset EGA_D_FBeg
	lea	dx,EGA_D_FBeg
	mov	ah,40h
	int	21h            ; Пишем в файл загрузчик

       	mov	ax,0A000h
	mov	ds,ax

        xor	cx,cx


EGA_D_Loop:
        mov     dx,3CEh    ;  │
        mov     al,5       ;  │
        out     dx,al      ;  │ Установим режим чтения
        inc     dx         ;  │
        mov     al,0       ;  │
        out     dx,al      ;  │
        dec	dx         ;  │
        mov     al,4       ;  │ Установим нужную битовую карту
        out     dx,al      ;  │
        inc     dx         ;  │
        mov     al,cl      ;  │ В cl номер карты
        out     dx,al      ;  │

        mov	ah,40h
        cwd
        push	cx
        mov	cx,0FA0h*2
        int	21h
        pop	cx
        inc	cx
        cmp	cl,4
        jnz	EGA_D_Loop


        mov	ah,3Eh
        int	21h

        jmp	EXIT_PROCESSING

PROCESSING:
	pushf
	cmp	byte ptr cs:pressed+1,1
	mov	byte ptr cs:pressed+1,0
	jz	PROC_CONT

	push	ax
	push	bx
	push	cx
	push	es
	push	ds

	push	cs
	pop	ds

	xor	ax,ax
	mov	es,ax

	mov	bx,word ptr es:[9*4]
	mov	cx,word ptr es:[9*4+2]

	
	mov	ax,cs
	cmp	ax,cx

	jnz	SetNew9
	cmp	bx,offset Int9_0
	jnz	SetNew9

GoodBye_:
	pop	ds
	pop	es	
	pop	cx
	pop	bx
	pop	ax
	popf
	ret

SetNew9:
	cmp	bx,offset Int9_1
	jz	GoodBye_
	mov	word ptr ds:old9o_1,bx
	mov	word ptr ds:old9s_1,cx

	mov	word ptr es:[9*4],offset Int9_1
	mov	word ptr es:[9*4+2],ds

	jmp	GoodBye_

PROC_CONT:
	call	SetNormInt8
	popf

Real_PROCESSING:
	pushf
	cli
        push    ax
        push    bx
        push    cx
        push    dx
        push    ds
	 
        push    cs
        pop     ds
	
	mov	byte ptr ds:Working,1	

	mov	ah,15
	pushf
	call	dword ptr old10o

	cmp	al,4			;CGA(4)
	jnz	NOT_CGA
CGA:
	mov	si,0B800h
	mov	di,1FA0h		;Пpовеpено
	jmp	SinglePanel_WRITE_FILE

	cmp	al,6
	jz	CGA	
NOT_CGA:
	cmp	al,11h
	jnz	NOT_MCGA_MONO

	mov	si,0A000h
	mov	di,4B00h		;Пpовеpено
	jmp	SinglePanel_WRITE_FILE
	
NOT_MCGA_MONO:
        cmp     al,10h			;EGA(16) 640*350
        jnz     NOT_EGA_10h

        mov     cx,36B8h		;Пpовеpено
        jmp	FourPanel_WRITE_FILE

NOT_EGA_10h:
	cmp	al,13h			;MCGA(256)
	jnz	NOT_MCGA_256
	mov	si,0A000h
	mov	di,7D00h		;Пpовеpено
	jmp	SinglePanel_WRITE_FILE

NOT_MCGA_256:
	cmp	al,0Dh
	jnz	NOT_EGA_0Dh
	jmp	EGA_D_WRITE_FILE


NOT_EGA_0Dh:
	cmp	al,12h
	jnz	Not_VgaHi
	mov	cx,4B00h		;Пpовеpено
	jmp	FourPanel_WRITE_FILE	


Not_VgaHi:

EXIT_PROCESSING:
	push	cs
	pop	ds
        mov	FourPanel_LOADER_PANEL_NUM,1

	call	IncCutNo
	mov     Panel_NUM,0
	mov	byte ptr ds:Working,0

        pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
	popf
	ret

int08:
	call	SetNormInt8
	push	ax
	push	bx
	push	si
	push	ds
	
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr cs:old08o
	mov	word ptr ds:[8*4],ax
	mov	ax,word ptr cs:old08s
	mov	word ptr ds:[8*4+2],ax

	mov	bx,sp

	mov	ds,word ptr ss:[bx+10]
	mov	si,word ptr ss:[bx+8]
	mov	al,byte ptr ss:[bx+13]
	mov	byte ptr cs:Flag,al		
	mov	byte ptr ss:[bx+13],0	
	
	mov	ax,word ptr ds:[si]
	mov	word ptr cs:LocTMP,ax
	mov	word ptr ds:[si],88CDh 		
	mov	word ptr cs:LocOff,si
	mov	word ptr cs:LocSeg,ds	
	
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr ds:[88h*4]
	mov	word ptr cs:old88o,ax
	mov	ax,word ptr ds:[88h*4+2]
	mov	word ptr cs:old88s,ax
	
	mov	word ptr ds:[88h*4],offset Int88
	mov	word ptr ds:[88h*4+2],cs

	pop	ds
	pop	si	
	pop	bx
	pop	ax
Exit08:
	db 	0EAh	
old08o	dw	0
old08s	dw	0
old88o	dw	0
old88s	dw	0
LocTMP	dw	0
LocOff	dw	0
LocSeg	dw	0
Flag	db	0
UseMe	dw	0


int10:
	call	PROCESSING
	db 	0EAh	
old10o	dw	0
old10s	dw	0

int13:
	call	PROCESSING
	db 	0EAh	
old13o	dw	0
old13s	dw	0

int16:

	pushf
	cmp	ax,7777h
	jnz	NOT_CHECKING
	cmp	cx,ax
	jnz	NOT_CHECKING	
	cmp	bx,ax
	jnz	NOT_CHECKING
	mov	al,26h
	popf	
	iret
NOT_CHECKING:
	popf
	call	PROCESSING
	db 	0EAh	
old16o	dw	0
old16s	dw	0

int21:
	call	PROCESSING
	db 	0EAh	
old21o	dw	0
old21s	dw	0


int28:

	call	PROCESSING
	db 	0EAh	
old28o	dw	0
old28s	dw	0

Int88:
	mov	byte ptr cs:pressed+1,0
	call	Real_PROCESSING

	push	ax
	push	bx
	push	ds

	mov	ds,word ptr cs:LocSeg
	mov	bx,word ptr cs:LocOff
	mov	ax,word ptr cs:LocTMP
	mov	word ptr ds:[bx],ax

	mov	bx,sp
	sub	word ptr ss:[bx+6],2
	mov	al,byte ptr cs:Flag
	mov	byte ptr ss:[bx+11],al	

	xor	ax,ax
	mov	ds,ax

	mov	ax,word ptr cs:old88o
	mov	word ptr ds:[88h*4],ax
	mov	ax,word ptr cs:old88s
	mov	word ptr ds:[88h*4+2],ax

	pop	ds
	pop	bx
	pop	ax	
	iret

SetNormInt8:
	push	ax
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr cs:old08o
	mov	word ptr ds:[8*4],ax
	mov	ax,word ptr cs:old08s
	mov	word ptr ds:[8*4+2],ax
	pop	ds
	pop	ax
	ret


fname	   db	'$cut$_'
CutNo_Hi  db   '0'
CutNo_Lo  db   '0'
Cont_fname db   '.com',0

IncCutNo:
	cmp	CutNo_Lo,'9'
	jnz	NotCutLo9
	mov	CutNo_Lo,'A'
	ret
NotCutLo9:
	cmp	CutNo_Lo,'Z'
	jnz	NotCutLoZ
	mov	CutNo_Lo,'0'
	cmp	CutNo_Hi,'Z'
	jnz	NotCutHiZ
	mov	CutNo_Hi,'0'
	ret
NotCutHiZ:
	cmp	CutNo_Hi,'9'
	jnz	NotCutHi9
	mov	CutNo_Hi,'A'
	ret
NotCutHi9:
	inc	CutNo_Hi
	ret
NotCutLoZ:
	inc	CutNo_Lo
	ret

PANEL_NUM       db 0

INSTALL:
	jmp	short PRGBEG


SI9o	dw	0
SI9s	dw	0

Int9TurnedOff:
	push	ax
	mov	al,20h
	out	20h,al
	pop	ax
	iret

SetInt9off:
	push	ax
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr ds:[9*4]
	mov	word ptr cs:SI9o,ax
	mov	ax,word ptr ds:[9*4+2]
	mov	word ptr cs:SI9s,ax
	mov	word ptr ds:[9*4],offset Int9TurnedOff
	mov	word ptr ds:[9*4+2],cs
	pop	ds
	pop	ax
	ret

SetInt9on:
	push	ax
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr cs:SI9o
	mov	word ptr ds:[9*4],ax
	mov	ax,word ptr cs:SI9s
	mov	word ptr ds:[9*4+2],ax
	pop	ds
	pop	ax
	ret

PRGBEG:
        cli
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr ds:[9*4]
	mov	word ptr cs:old08o,ax
	mov	ax,word ptr ds:[9*4+2]
	mov	word ptr cs:old08s,ax

	mov	ax,word ptr ds:[21h*4]
	mov	word ptr cs:old88o,ax
	mov	ax,word ptr ds:[21h*4+2]
	mov	word ptr cs:old88s,ax
	
	mov	word ptr ds:[9*4],offset FckInt9
	mov	word ptr ds:[9*4+2],cs

	
	push	cs
	pop	ds
	lea	dx,MSG0
	mov	ah,9
	int	9h
	mov	ax,7777h
	mov	cx,ax
	mov	bx,ax
	int	16h
	cmp	al,26h
	jnz	INST
	lea	dx,MSG1
	mov	ah,9
	int	9h
	lea	dx,LINE
	mov	ah,9
	int	9h
        xor     ax,ax
        mov     ds,ax
        mov     ax,word ptr cs:old08o
        mov     word ptr ds:[9*4],ax
        mov     ax,word ptr cs:old08s
        mov     word ptr ds:[9*4+2],ax
        mov     di,100h
        mov     al,1
        cld
	push	cs
	pop	es
EndFck: mov     cx,offset EndFck-100h
        rep     stosb
        mov     ax,4C01h
	int     21h

FckInt9:
	call	SetInt9off
	pushf
	call	dword ptr cs:old88o
	call	SetInt9on
	mov	bp,sp
	mov	word ptr ss:[bp+2],cs
	iret
	
INST:

	mov	es,word ptr ds:[2Ch]
	mov	ah,49h
	int     9h

	mov	ax,3510h
	int     9h
	mov	old10o,BX
	mov	old10s,ES
	lea	dx,int10
	mov	ax,2510h
	int	9h

	mov	ax,3513h
	int     9h
	mov	old13o,BX
	mov	old13s,ES
	lea	dx,int13
	mov	ax,2513h
	int     9h

	mov	ax,3516h
	int	9h
	mov	old16o,BX
	mov	old16s,ES
	lea	dx,int16
	mov	ax,2516h
	int     9h

	mov	ax,3521h
	int	9h
	mov	old21o,BX
	mov	old21s,ES
	lea	dx,int21
	mov	ax,2521h
	int     9h

	mov	ax,3528h
	int     9h
	mov	old28o,BX
	mov	old28s,ES
	lea	dx,int28
	mov	ax,2528h
	int     9h

	lea	dx,MSG2
	mov	ah,9
	int     9h
	lea	dx,LINE
	mov	ah,9
	int	9h

        mov     ax,word ptr ds:old08o
        mov     word ptr ds:old9o_0,ax
        mov     ax,word ptr ds:old08s
        mov     word ptr ds:old9s_0,ax

        xor     ax,ax
        mov     ds,ax

        mov     word ptr ds:[9*4],offset int9_0
        mov     word ptr ds:[9*4+2],cs

	lea	dx,INSTALL
        sti
	int	27h

MSG2	db	10,13,'Installed.',10,13
	db	'Advanced ScrGrab  ─ ON. Hot key <CTRL>-<PrtScr>',10,13
	db	'Advanced Restart  ─ ON. Hot key <CTRL>-<Alt>-"D"',10,13
	db	'Advanced Pause    ─ ON. Hot key <CTRL>-<Alt>-"P"',10,13
	db	'Clear internal counter - <CTRL>-<Alt>-"C"',10,13,10,13
	db	'Make sure CTRL.EXE is last resident utility in AUTOEXEC.BAT'
        db      10,13,'$'
MSG0	db	10,13,10,13,10
	db '────────────────────────────────────────────── RSsoftware (638-014) ──────',10,13
	db 'CTRL  Version 1.0  Software Product  Copyright (C) 1992,93 by MasyutinMax~',10,13
LINE	db '──────────────────────────────────────────────────────────────────────────',10,13,'$'
MSG1	db	'CTRL was already installed !',10,13,'$'
CODE	ends
	end	START

