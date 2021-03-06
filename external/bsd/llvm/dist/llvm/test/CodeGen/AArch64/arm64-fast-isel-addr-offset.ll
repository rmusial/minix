; RUN: llc -O0 -fast-isel-abort -verify-machineinstrs -mtriple=arm64-apple-darwin < %s | FileCheck %s

@sortlist = common global [5001 x i32] zeroinitializer, align 16
@sortlist2 = common global [5001 x i64] zeroinitializer, align 16

; Load an address with an offset larget then LDR imm can handle
define i32 @foo() nounwind {
entry:
; CHECK: @foo
; CHECK: adrp x[[REG:[0-9]+]], _sortlist@GOTPAGE
; CHECK: ldr x[[REG1:[0-9]+]], [x[[REG]], _sortlist@GOTPAGEOFF]
; CHECK: movz x[[REG2:[0-9]+]], #0x4e20
; CHECK: add x[[REG3:[0-9]+]], x[[REG1]], x[[REG2]]
; CHECK: ldr w0, [x[[REG3]]]
; CHECK: ret
  %0 = load i32* getelementptr inbounds ([5001 x i32]* @sortlist, i32 0, i64 5000), align 4
  ret i32 %0
}

define i64 @foo2() nounwind {
entry:
; CHECK: @foo2
; CHECK: adrp x[[REG:[0-9]+]], _sortlist2@GOTPAGE
; CHECK: ldr x[[REG1:[0-9]+]], [x[[REG]], _sortlist2@GOTPAGEOFF]
; CHECK: movz x[[REG2:[0-9]+]], #0x9c40
; CHECK: add x[[REG3:[0-9]+]], x[[REG1]], x[[REG2]]
; CHECK: ldr x0, [x[[REG3]]]
; CHECK: ret
  %0 = load i64* getelementptr inbounds ([5001 x i64]* @sortlist2, i32 0, i64 5000), align 4
  ret i64 %0
}

; Load an address with a ridiculously large offset.
; rdar://12505553
@pd2 = common global i8* null, align 8

define signext i8 @foo3() nounwind ssp {
entry:
; CHECK: @foo3
; CHECK: movz x[[REG:[0-9]+]], #0xb3a, lsl #32
; CHECK: movk x[[REG]], #0x73ce, lsl #16
; CHECK: movk x[[REG]], #0x2ff2
  %0 = load i8** @pd2, align 8
  %arrayidx = getelementptr inbounds i8* %0, i64 12345678901234
  %1 = load i8* %arrayidx, align 1
  ret i8 %1
}
