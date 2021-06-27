name	hitsuji
title	眠れない夜だってあるさ
;
;	『 眠れない夜だってあるさ 』
;

INT0AH	equ	0ah
LF	equ	0ah
CR	equ	0dh
;

CODE	segment
	assume	cs:CODE,ds:CODE
;
;	PSP領域 (0ch～0ffh)
;
	org	2ch
envseg	dw	?
	org	80h
argc	db	?
argv	db	127 dup (?)

stktop	label	word

;
;---------------------------------------------------------------------
;
	org	100h

start:	jmp	initial

;
;	垂直同期割り込み処理（常駐本体）
;

ss_reg	dw	?
sp_reg	dw	?

count	dw	200
rate	dw	200
hitsuji	dw	0

new0a	proc
	mov	cs:[ss_reg],ss
	mov	cs:[sp_reg],sp
	push	cs
	pop	ss
	mov	sp,offset stktop
	
	irp	reg,<ax,bx,cx,dx,si,ds,es>
		push reg
	endm
	
	dec	cs:[count]
	jz	st_1
	jmp	exit2
	
st_1:	mov	ax,cs:[rate]
	mov	cs:[count],ax
	
	mov	ax,0a000h
	mov	ds,ax
	
	mov	ax,cs:[hitsuji]
	inc	ax
	cmp	ax,0ffffh
	jne	madamada
	mov	ax,0
madamada:
	mov	cs:[hitsuji],ax
	mov	cx,0
	
	mov	ds:[1988],532dh
	mov	ds:[1992],2c04h
mann:	mov	dx,0
	mov	bx,10000
	div	bx
	cmp	ax,0
	je	senn
	mov	cx,1
mann_w:	add	ax,'0'
	mov	ds:[1998],ax
senn:	mov	ax,dx
	mov	dx,0
	mov	bx,1000
	div	bx
	cmp	cx,1
	je	senn_w
	cmp	ax,0
	je	hyak
	mov	cx,1
senn_w:	add	ax,'0'
	mov	ds:[2000],ax
hyak:	mov	ax,dx
	mov	dx,0
	mov	bx,100
	div	bx
	cmp	cx,1
	je	hyak_w
	cmp	ax,0
	je	jyuu
	mov	cx,1
hyak_w:	add	ax,'0'
	mov	ds:[2002],ax
jyuu:	mov	ax,dx
	mov	dx,0
	mov	bx,10
	div	bx
	cmp	cx,1
	je	jyuu_w
	cmp	ax,0
	je	ichi
jyuu_w:	add	ax,'0'
	mov	ds:[2004],ax
ichi:	add	dx,'0'
	mov	ds:[2006],dx
	
	mov	ds:[2010],2429h
	
;出口
exit2:	mov	al,20h
	out	00h,al
	out	64h,al
	
	irp	reg,<es,ds,si,dx,cx,bx,ax>
		pop	reg
	endm
	
	mov	sp,cs:[sp_reg]
	mov	ss,cs:[ss_reg]
	
;問答無用！
jmpold:	iret
	
old0ah	dd	?
	
new0a	endp

breakadr label	byte

;
;---------------------------------------------------------------------
;
;	初期化部分
;

initial:
	cmp	[argc],0
	jz	argend
	mov	si,offset argv
arglp:	call	getarg
	cmp	al,CR
	je	argend
	cmp	al,'R'		;常駐解除
	je	argr
	cmp	al,'1'
	jb	unknown
	cmp	al,'9'
	ja	unknown
	jmp	argnum		;残りは数字だ
;知らぬオプション
unknown:
	mov	dx,offset unk$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h

;表示タイミング
argnum:	sub	al,'0'
	mov	bl,30
	mul	bl
	mov	ah,0
	mov	cs:[rate],ax
	jmp	arglp

argend:
	mov	ax,3500h+INT0AH
	int	21h
	call	chkmem
	jz	exist
	mov	word ptr cs:[old0ah],bx
	mov	word ptr cs:[old0ah+2],es
	mov	ax,2500h+INT0AH
	mov	dx,offset new0a
	int	21h
;
;	環境変数の解放
;
	mov	es,[envseg]
	mov	ah,49h
	int	21h
	mov	[envseg],0
;
;	常駐処理
;
	mov	dx,offset reside$
	mov	ah,09h
	int	21h
	
	cli
	in	al,02h
	and	al,0fbh
	out	02h,al
	sti
	out	64h,al
	
	mov	ah,40h
	int	18h
	
	lea	dx,[breakadr+0fh]
	mov	cl,4
	shr	dx,cl
	mov	ax,3100h
	int	21h

;実は既に常駐していた
exist:	mov	dx,offset exist$
	mov	ah,09h
	int	21h
	out	64h,al
	mov	ax,4c01h
	int	21h
;
;	常駐解放
;
argr:
	mov	ax,3500h+INT0AH
	int	21h
	call	chkmem
	jnz	notexist
	push	ds
	lds	dx,es:[old0ah]
	mov	ax,2500h+INT0AH
	int	21h
	pop	ds
	mov	ah,49h
	int	21h
	jc	relerr
	mov	dx,offset rel$
	mov	ah,09h
	int	21h
	mov	ax,4c00h
	int	21h
;解放失敗
relerr:
	mov	dx,offset relerr$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
;実は常駐していなかった
notexist:
	mov	dx,offset notex$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
;
;	メモリ常駐確認
;
chkmem	proc
	mov	si,offset new0a
	mov	di,offset new0a
	mov	cx,(offset exit2 - offset new0a)
	cld
	repe	cmpsb
	ret
chkmem	endp

;
;	引数取得
;
getarg	proc
	lodsb
	cmp	al,' '
	jz	getarg
	cmp	al,09h
	jz	getarg
	cmp	al,','
	jz	getarg
	cmp	al,'-'
	jz	getarg
	cmp	al,'/'
	jz	getarg
	cmp	al,'a'
	jb	getarge
	cmp	al,'z'
	ja	getarge
	sub	al,'a'-'A'
getarge:
	ret
getarg	endp

unk$	db	"usage : hitsuji [1..9][r]",CR,LF,"$"
reside$	db	"　　「僕にだって眠れない夜だってあるさ」",CR,LF,"$"
exist$	db	"孫　「まだまだ眠れないの？」",CR,LF,"$"
rel$	db	01bh,"[2J",CR,LF,CR,LF
	db	"作者「おっはよぉ！！！！",CR,LF
	db	"      本当に気持ちのいい朝だネ！！！！」",CR,LF,"$"
relerr$	db	"作者「スミマセン……(汗;)。",CR,LF
	db	"      一生,羊を数えることになってしまいました。」",CR,LF,"$"
notex$	db	"老人「まだ、常駐しておらんわい。」",CR,LF,"$"

CODE	ends
	end	start
