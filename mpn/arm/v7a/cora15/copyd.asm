dnl  ARM mpn_copyd.

dnl  Copyright 2013 Free Software Foundation, Inc.

dnl  This file is part of the GNU MP Library.

dnl  The GNU MP Library is free software; you can redistribute it and/or modify
dnl  it under the terms of the GNU Lesser General Public License as published
dnl  by the Free Software Foundation; either version 3 of the License, or (at
dnl  your option) any later version.

dnl  The GNU MP Library is distributed in the hope that it will be useful, but
dnl  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
dnl  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
dnl  License for more details.

dnl  You should have received a copy of the GNU Lesser General Public License
dnl  along with the GNU MP Library.  If not, see http://www.gnu.org/licenses/.

include(`../config.m4')

C	     cycles/limb
C StrongARM	 ?
C XScale	 ?
C Cortex-A8	 ?
C Cortex-A9	 1.75		slower than core register code
C Cortex-A15	 0.52

define(`rp', `r0')
define(`up', `r1')
define(`n',  `r2')

ASM_START()
PROLOGUE(mpn_copyd)
	mov	r12, n, lsl #2
	add	rp, rp, r12
	add	up, up, r12

	cmp	n, #7
	ble	L(bc)

C Copy until rp is 128-bit aligned
	tst	rp, #4
	beq	L(al1)
	sub	up, up, #4
	vld1.32	{d22[0]}, [up]
	sub	n, n, #1
	sub	rp, rp, #4
	vst1.32	{d22[0]}, [rp]
L(al1):	tst	rp, #8
	beq	L(al2)
	sub	up, up, #8
	vld1.32	{d22}, [up]
	sub	n, n, #2
	sub	rp, rp, #8
	vst1.32	{d22}, [rp:64]
L(al2):	sub	up, up, #16
	vld1.32	{d26-d27}, [up]
	subs	n, n, #12
	sub	rp, rp, #16			C offset rp for loop
	blt	L(end)

	sub	up, up, #16			C offset up for loop
	mov	r12, #-16

	ALIGN(16)
L(top):	vld1.32	{d22-d23}, [up], r12
	vst1.32	{d26-d27}, [rp:128], r12
	vld1.32	{d26-d27}, [up], r12
	vst1.32	{d22-d23}, [rp:128], r12
	subs	n, n, #8
	bge	L(top)

	add	up, up, #16			C undo up offset
						C rp offset undoing folded
L(end):	vst1.32	{d26-d27}, [rp:128]

C Copy last 0-7 limbs.  Note that rp is aligned after loop, but not when we
C arrive here via L(bc)
L(bc):	tst	n, #4
	beq	L(tl1)
	sub	up, up, #16
	vld1.32	{d22-d23}, [up]
	sub	rp, rp, #16
	vst1.32	{d22-d23}, [rp]
L(tl1):	tst	n, #2
	beq	L(tl2)
	sub	up, up, #8
	vld1.32	{d22}, [up]
	sub	rp, rp, #8
	vst1.32	{d22}, [rp]
L(tl2):	tst	n, #1
	beq	L(tl3)
	sub	up, up, #4
	vld1.32	{d22[0]}, [up]
	sub	rp, rp, #4
	vst1.32	{d22[0]}, [rp]
L(tl3):	bx	lr
EPILOGUE()
