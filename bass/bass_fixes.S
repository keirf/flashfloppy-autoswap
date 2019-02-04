/*
 * bass_fixes.S
 *
 * Cracks/fixes for Beneath a Steel Sky. Most of this code is from
 * WHDLoad installer written by JOTD, so thanks to him!
 *
 * Hacked together & released by Keir Fraser <keir.xen@gmail.com>
 *
 * This is Public Domain! See below for original WHDLoad credits.
 */

/* LibBase offsets */
#define LibBase_Version 20

/* Exec library calls */
#define Exec_CacheClearU  -0x27c

        .text
start:
        movem.l d0-d7/a0-a7,-(sp)
        move.l  start-4(pc),d7
        lsl.l   #2,d7
        addq.l  #4,d7
        move.l  d7,15*4(sp)             /* patch return address */
        jbsr    patchgame
        move.l  4.w,a6
        cmp.w   #37,LibBase_Version(a6) /* exec.lib_version >= 37? */
        jcs     1f
        jsr     Exec_CacheClearU(a6)
1:      movem.l (sp)+,d0-d7/a0-a6
        rts

/* Everything below here is from the WHDLoad installer, modified by me for
 * GAS syntax and to remove references to WHDLoad runtime. - KAF */
        
/*---------------------------------------------------------------------------
 * :Program.	BeneathASteelSkyHD.asm
 * :Contents.	Slave for "BeneathASteelSky"
 * :Author.	JOTD, from Wepl sources
 * :Original	v1 
 * :Version.	$Id: BeneathASteelSkyHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
 * :History.	%DATE% started
 * :Requires.	-
 * :Copyright.	Public Domain
 * :Language.	68000 Assembler
 * :Translator.	Devpac 3.14, Barfly 2.9
 * :To Do.
 *---------------------------------------------------------------------------*/

patchgame:
	jbsr	.getbounds

	lea	.af_load(pc),A2
	moveq.l	#6,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip0

	pea	af_load(pc)
	move.w	#0x4EB9,(A0)+
	move.l	(A7)+,(A0)+
.skip0:

	// access fault (1)

	jbsr	.getbounds

	lea	.af(pc),A2
	move.l	#10,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2

	move.l	#0x4EB80100,(A0)
        move.w  #0x4ef9,0x100.w
        pea     avoid_af(pc)
        move.l  (sp)+,0x102.w
.skip2:

	// access fault (2), file decryption problem

	jbsr	.getbounds

	lea	.af_2(pc),A2
	move.l	#8,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip22

	pea	avoid_crash(pc)
	move.w	#0x4EF9,(A0)+
	move.l	(A7)+,(A0)
.skip22:
	// access fault (3), at very late stages of the game, menu problem

	jbsr	.getbounds

	lea	.af_3(pc),A2
	move.l	#8,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip23

	pea	late_menu_correction(pc)
	addq.l	#6,A0
	move.w	#0x4EF9,(A0)+
	move.l	(A7)+,(A0)
.skip23:
	jbsr	.getbounds	
	lea	.crack1(pc),A2
	move.l	#10,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip4
	move.b	#0xFE,2(a0)
.skip4:
	jbsr	.getbounds	
	lea	.crack2(pc),A2
	move.l	#32,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip5
	move.b	#0x50,30(a0)
.skip5:
	jbsr	.getbounds	
	lea	.crack3(pc),A2
	move.l	#10,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip6
	move.l	#0x34C0B040,2(a0)
.skip6:
	jbsr	.getbounds	
	lea	.readbug(pc),A2
	move.l	#12,D0
	jbsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip7
	move.b	#0x6B,10(a0)	// BNE -> BMI program error + kickfs bug workaround
.skip7:

	rts

.getbounds:
	move.l	d7,A0
//	add.l	#4,a0
	move.l	A0,a1	
	add.l	#0x40000,A1
	rts

.af_load:
	dc.l	0x24690030
	dc.w	0x4A52

.readbug:        
	dc.l	0x767F4843,0x4EAEFFD6,0x4A806600

.crack1:
	dc.w	0,0xFFFE,0,0x18,0x18
.crack2:
	dc.l	0x51AA,0,0,0,0,0,0,0x51DB
.crack3:
	dc.w	0x141,0x321A,0xB240,0x6600,0x0016

.af:
	dc.l	0x3358000E,0x33500010
	dc.w	0x0469			// first menu access fault
.af_2:
	dc.l	0x2C730000,0xDDCB4ED6	// the one which makes LINC crash
.af_3:
	dc.l	0x22711000,0xE548D3F1	// late menu access fault
	
.normal:
	move.w	#3,D1
	jmp	(A0)

af_load:
	movem.l	D0,-(a7)
	MOVE.L	0x0030(A1),D0
	swap	d0
	cmp.w	#0x0AB5,d0
	bne.b	1f
	move.l	#0x05000000,d0	// access to a stupid address (0x500)
				// maybe, but within bounds and filled with zeroes!
1:
	swap	d0
	move.l	d0,a2
	movem.l	(a7)+,d0
	TST.W	(A2)
	rts

avoid_crash:
	move.l	D1,-(a7)
	move.l	(A3,D0.W),D1
	and.l	#0xFFFFFF,D1	// avoids access fault with LINC
	move.l	D1,A6
	add.l	A3,A6
	move.l	(A7)+,D1
	jmp	(A6)

avoid_af:
	movem.l	D0/D1,-(A7)
	move.l	A1,D0
	movem.l	(A7)+,D0/D1
	bpl.b	.ok

	// access fault on 0xFFFFxxxx address: return with D0=1

	moveq.l	#1,D0
	addq.l	#4,A7
	rts

.ok:
	move.w	(A0)+,0xE(A1)	// stolen code
	rts

late_menu_correction:
	move.l	(A1,D0.W),D1
	and.l	#0xFFFFFF,D1	// removes MSB which causes access fault
	add.l	D1,A1
	move.l	(A7)+,D1
	rts


//< A0: start
//< A1: end
//< A2: bytes
//< D0: length
//> A0: address or 0 if not found

_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	// gets byte
	cmp.b	(A2,D3.L),D1	// compares it to the user string
	bne.b	.notok		// nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	// pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	// next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	// end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts
