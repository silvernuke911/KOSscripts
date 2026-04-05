	.file	"fib.cpp"
	.text
	.section	.text$_Z5scanfPKcz,"x"
	.linkonce discard
	.globl	_Z5scanfPKcz
	.def	_Z5scanfPKcz;	.scl	2;	.type	32;	.endef
	.seh_proc	_Z5scanfPKcz
_Z5scanfPKcz:
.LFB3:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$56, %rsp
	.seh_stackalloc	56
	leaq	48(%rsp), %rbp
	.seh_setframe	%rbp, 48
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	%r8, 48(%rbp)
	movq	%r9, 56(%rbp)
	leaq	40(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rbx
	movl	$0, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	movq	32(%rbp), %rax
	movq	%rbx, %r8
	movq	%rax, %rdx
	call	__mingw_vfscanf
	movl	%eax, -4(%rbp)
	movl	-4(%rbp), %eax
	addq	$56, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_Z6printfPKcz,"x"
	.linkonce discard
	.globl	_Z6printfPKcz
	.def	_Z6printfPKcz;	.scl	2;	.type	32;	.endef
	.seh_proc	_Z6printfPKcz
_Z6printfPKcz:
.LFB9:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$56, %rsp
	.seh_stackalloc	56
	leaq	48(%rsp), %rbp
	.seh_setframe	%rbp, 48
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	%r8, 48(%rbp)
	movq	%r9, 56(%rbp)
	leaq	40(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rbx
	movl	$1, %ecx
	movq	__imp___acrt_iob_func(%rip), %rax
	call	*%rax
	movq	%rax, %rcx
	movq	32(%rbp), %rax
	movq	%rbx, %r8
	movq	%rax, %rdx
	call	__mingw_vfprintf
	movl	%eax, -4(%rbp)
	movl	-4(%rbp), %eax
	addq	$56, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.def	__main;	.scl	2;	.type	32;	.endef
	.section .rdata,"dr"
.LC1:
	.ascii "%lf\0"
	.align 8
.LC2:
	.ascii "Cannot compute square root of negative number!\12\0"
.LC7:
	.ascii "\12\0"
.LC8:
	.ascii "%.15f\11%.15f\12\0"
	.align 8
.LC9:
	.ascii "\12Execution time: %.6f seconds\12\0"
	.text
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
.LFB1047:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$80, %rsp
	.seh_stackalloc	80
	.seh_endprologue
	call	__main
	pxor	%xmm0, %xmm0
	movsd	%xmm0, -8(%rbp)
	leaq	-40(%rbp), %rax
	movq	%rax, %rdx
	leaq	.LC1(%rip), %rax
	movq	%rax, %rcx
	call	_Z5scanfPKcz
	call	clock
	movl	%eax, -20(%rbp)
	movsd	-40(%rbp), %xmm1
	pxor	%xmm0, %xmm0
	comisd	%xmm1, %xmm0
	jbe	.L13
	leaq	.LC2(%rip), %rax
	movq	%rax, %rcx
	call	_Z6printfPKcz
	movl	$1, %eax
	jmp	.L11
.L13:
	movsd	-40(%rbp), %xmm0
	movsd	.LC3(%rip), %xmm1
	divsd	%xmm1, %xmm0
	movsd	%xmm0, -16(%rbp)
	jmp	.L9
.L10:
	movsd	-16(%rbp), %xmm0
	movsd	%xmm0, -8(%rbp)
	movsd	-40(%rbp), %xmm0
	divsd	-16(%rbp), %xmm0
	addsd	-16(%rbp), %xmm0
	movsd	.LC3(%rip), %xmm1
	divsd	%xmm1, %xmm0
	movsd	%xmm0, -16(%rbp)
.L9:
	movsd	-16(%rbp), %xmm0
	subsd	-8(%rbp), %xmm0
	movq	.LC4(%rip), %xmm1
	andpd	%xmm1, %xmm0
	comisd	.LC5(%rip), %xmm0
	ja	.L10
	call	clock
	movl	%eax, -24(%rbp)
	movl	-24(%rbp), %eax
	subl	-20(%rbp), %eax
	pxor	%xmm0, %xmm0
	cvtsi2sdl	%eax, %xmm0
	movsd	.LC6(%rip), %xmm1
	divsd	%xmm1, %xmm0
	movsd	%xmm0, -32(%rbp)
	leaq	.LC7(%rip), %rax
	movq	%rax, %rcx
	call	_Z6printfPKcz
	movsd	-40(%rbp), %xmm0
	movq	%xmm0, %rax
	movq	%rax, %rdx
	movq	%rdx, %xmm1
	movq	%rax, %rdx
	movsd	-16(%rbp), %xmm0
	movq	-16(%rbp), %rax
	movapd	%xmm1, %xmm2
	movq	%rdx, %r8
	movapd	%xmm0, %xmm1
	movq	%rax, %rdx
	leaq	.LC8(%rip), %rax
	movq	%rax, %rcx
	call	_Z6printfPKcz
	movsd	-32(%rbp), %xmm0
	movq	-32(%rbp), %rax
	movapd	%xmm0, %xmm1
	movq	%rax, %rdx
	leaq	.LC9(%rip), %rax
	movq	%rax, %rcx
	call	_Z6printfPKcz
	movl	$0, %eax
.L11:
	addq	$80, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC3:
	.long	0
	.long	1073741824
	.align 16
.LC4:
	.long	-1
	.long	2147483647
	.long	0
	.long	0
	.align 8
.LC5:
	.long	-1629006314
	.long	1020396463
	.align 8
.LC6:
	.long	0
	.long	1083129856
	.ident	"GCC: (MinGW-W64 x86_64-msvcrt-posix-seh, built by Brecht Sanders) 13.1.0"
	.def	__mingw_vfscanf;	.scl	2;	.type	32;	.endef
	.def	__mingw_vfprintf;	.scl	2;	.type	32;	.endef
	.def	clock;	.scl	2;	.type	32;	.endef
