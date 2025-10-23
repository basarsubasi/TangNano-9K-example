
build/fw-brom.elf:     file format elf32-littleriscv


Disassembly of section .memory:

80000000 <crtStart>:

.global crtStart
.global main

crtStart:
  j crtInit
80000000:	0200006f          	j	80000020 <crtInit>
  nop
80000004:	00000013          	nop
  nop
80000008:	00000013          	nop
  nop
8000000c:	00000013          	nop
  nop
80000010:	00000013          	nop
  nop
80000014:	00000013          	nop
  nop
80000018:	00000013          	nop
  nop
8000001c:	00000013          	nop

80000020 <crtInit>:

crtInit:
  .option push
  .option norelax
  la gp, __global_pointer$
80000020:	00001197          	auipc	gp,0x1
80000024:	b7818193          	addi	gp,gp,-1160 # 80000b98 <__global_pointer$>
  .option pop
  la sp, _stack_start
80000028:	a0818113          	addi	sp,gp,-1528 # 800005a0 <_stack_start>

8000002c <bss_init>:

bss_init:
  la a0, _bss_start
8000002c:	00000517          	auipc	a0,0x0
80000030:	36c50513          	addi	a0,a0,876 # 80000398 <_bss_end>
  la a1, _bss_end
80000034:	00000597          	auipc	a1,0x0
80000038:	36458593          	addi	a1,a1,868 # 80000398 <_bss_end>

8000003c <bss_loop>:
bss_loop:
  beq a0,a1,bss_done
8000003c:	00b50863          	beq	a0,a1,8000004c <bss_done>
  sw zero,0(a0)
80000040:	00052023          	sw	zero,0(a0)
  add a0,a0,4
80000044:	00450513          	addi	a0,a0,4
  j bss_loop
80000048:	ff5ff06f          	j	8000003c <bss_loop>

8000004c <bss_done>:
bss_done:

  call main
8000004c:	178000ef          	jal	800001c4 <main>

80000050 <infinitLoop>:
infinitLoop:
  j infinitLoop
80000050:	0000006f          	j	80000050 <infinitLoop>

Disassembly of section .text.spi_flashio:

80000054 <spi_flashio>:
    return txdata;
}

void spi_flashio(uint8_t *pdata, int length, int wren) {
    // Set CS high, IO0 is output
    QSPI0->IOW = QSPI_OE_MOSI | QSPI_IO_CSb;
80000054:	810006b7          	lui	a3,0x81000
80000058:	12000793          	li	a5,288
8000005c:	00f69023          	sh	a5,0(a3) # 81000000 <__global_pointer$+0xfff468>
    
    // Enable Manual SPI Ctrl
    QSPI0->EN = 0;
80000060:	000681a3          	sb	zero,3(a3)

    // Send WREN cmd when requested
    if (wren) {
        QSPI0->IO = 0;
80000064:	00068023          	sb	zero,0(a3)
    if (wren) {
80000068:	10061063          	bnez	a2,80000168 <spi_flashio+0x114>
        QSPI0->IO = QSPI_IO_CSb;
    }

    // Perform actual data RW
    QSPI0->IO = 0;
    while (length) {
8000006c:	14058663          	beqz	a1,800001b8 <spi_flashio+0x164>
80000070:	00b50833          	add	a6,a0,a1
        QSPI0->IO = spi_io;
80000074:	810005b7          	lui	a1,0x81000
        *pdata = spi_trbyte(*pdata);
80000078:	00054703          	lbu	a4,0(a0)
8000007c:	00800693          	li	a3,8
        spi_io = (txdata >> 7) & QSPI_IO_MOSI;
80000080:	00775793          	srli	a5,a4,0x7
        QSPI0->IO = spi_io;
80000084:	00f58023          	sb	a5,0(a1) # 81000000 <__global_pointer$+0xfff468>
        spi_io |= QSPI_IO_CLK;
80000088:	0107e793          	ori	a5,a5,16
        QSPI0->IO = spi_io;
8000008c:	00f58023          	sb	a5,0(a1)
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
80000090:	0005c783          	lbu	a5,0(a1)
80000094:	00171713          	slli	a4,a4,0x1
    for (int i = 0; i < 8; i++) {
80000098:	fff68693          	addi	a3,a3,-1
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
8000009c:	0017d793          	srli	a5,a5,0x1
800000a0:	0017f793          	andi	a5,a5,1
800000a4:	00e7e7b3          	or	a5,a5,a4
800000a8:	0ff7f713          	zext.b	a4,a5
    for (int i = 0; i < 8; i++) {
800000ac:	fc069ae3          	bnez	a3,80000080 <spi_flashio+0x2c>
        *pdata = spi_trbyte(*pdata);
800000b0:	00e50023          	sb	a4,0(a0)
        pdata++;
800000b4:	00150513          	addi	a0,a0,1
    while (length) {
800000b8:	fd0510e3          	bne	a0,a6,80000078 <spi_flashio+0x24>
        length--;
    }
    QSPI0->IO = QSPI_IO_CSb;
800000bc:	02000793          	li	a5,32
800000c0:	00f58023          	sb	a5,0(a1)

    // Check WIP/BUSY bit when WREN issued
    if (wren) {
800000c4:	08060a63          	beqz	a2,80000158 <spi_flashio+0x104>
        uint8_t res;
        do {
            QSPI0->IO = 0;
800000c8:	81000737          	lui	a4,0x81000
            spi_trbyte(QSPI_FLASH_RDSR);
            res = spi_trbyte(0x00);
            QSPI0->IO = QSPI_IO_CSb;
800000cc:	02000513          	li	a0,32
            QSPI0->IO = 0;
800000d0:	00070023          	sb	zero,0(a4) # 81000000 <__global_pointer$+0xfff468>
800000d4:	00800613          	li	a2,8
800000d8:	00500693          	li	a3,5
        spi_io = (txdata >> 7) & QSPI_IO_MOSI;
800000dc:	0076d793          	srli	a5,a3,0x7
        QSPI0->IO = spi_io;
800000e0:	00f70023          	sb	a5,0(a4)
        spi_io |= QSPI_IO_CLK;
800000e4:	0107e793          	ori	a5,a5,16
        QSPI0->IO = spi_io;
800000e8:	00f70023          	sb	a5,0(a4)
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
800000ec:	00074783          	lbu	a5,0(a4)
800000f0:	00169693          	slli	a3,a3,0x1
    for (int i = 0; i < 8; i++) {
800000f4:	fff60613          	addi	a2,a2,-1
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
800000f8:	0017d793          	srli	a5,a5,0x1
800000fc:	0017f793          	andi	a5,a5,1
80000100:	00d7e7b3          	or	a5,a5,a3
80000104:	0ff7f693          	zext.b	a3,a5
    for (int i = 0; i < 8; i++) {
80000108:	fc061ae3          	bnez	a2,800000dc <spi_flashio+0x88>
8000010c:	00800613          	li	a2,8
80000110:	00000693          	li	a3,0
        spi_io = (txdata >> 7) & QSPI_IO_MOSI;
80000114:	0076d793          	srli	a5,a3,0x7
        QSPI0->IO = spi_io;
80000118:	00f70023          	sb	a5,0(a4)
        spi_io |= QSPI_IO_CLK;
8000011c:	0107e793          	ori	a5,a5,16
        QSPI0->IO = spi_io;
80000120:	00f70023          	sb	a5,0(a4)
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
80000124:	00074783          	lbu	a5,0(a4)
80000128:	00169693          	slli	a3,a3,0x1
    for (int i = 0; i < 8; i++) {
8000012c:	fff60613          	addi	a2,a2,-1
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
80000130:	0017d793          	srli	a5,a5,0x1
80000134:	0017f793          	andi	a5,a5,1
80000138:	00d7e7b3          	or	a5,a5,a3
8000013c:	01879593          	slli	a1,a5,0x18
80000140:	4185d593          	srai	a1,a1,0x18
80000144:	0ff7f693          	zext.b	a3,a5
    for (int i = 0; i < 8; i++) {
80000148:	fc0616e3          	bnez	a2,80000114 <spi_flashio+0xc0>
            QSPI0->IO = QSPI_IO_CSb;
8000014c:	00a70023          	sb	a0,0(a4)
        } while(res & QSPI_FLASHSR_WIP);
80000150:	0015f593          	andi	a1,a1,1
80000154:	f6059ee3          	bnez	a1,800000d0 <spi_flashio+0x7c>
    }

    // Return to XIP mode
    QSPI0->EN = QSPI_EN_ENABLE;
80000158:	810007b7          	lui	a5,0x81000
8000015c:	f8000713          	li	a4,-128
80000160:	00e781a3          	sb	a4,3(a5) # 81000003 <__global_pointer$+0xfff46b>
}
80000164:	00008067          	ret
        QSPI0->IO = 0;
80000168:	00800813          	li	a6,8
8000016c:	00600713          	li	a4,6
        spi_io = (txdata >> 7) & QSPI_IO_MOSI;
80000170:	00775793          	srli	a5,a4,0x7
        QSPI0->IO = spi_io;
80000174:	00f68023          	sb	a5,0(a3)
        spi_io |= QSPI_IO_CLK;
80000178:	0107e793          	ori	a5,a5,16
        QSPI0->IO = spi_io;
8000017c:	00f68023          	sb	a5,0(a3)
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
80000180:	0006c783          	lbu	a5,0(a3)
80000184:	00171713          	slli	a4,a4,0x1
    for (int i = 0; i < 8; i++) {
80000188:	fff80813          	addi	a6,a6,-1
        txdata = (txdata << 1) | ((QSPI0->IO & QSPI_IO_MISO) >> 1);
8000018c:	0017d793          	srli	a5,a5,0x1
80000190:	0017f793          	andi	a5,a5,1
80000194:	00e7e7b3          	or	a5,a5,a4
80000198:	0ff7f713          	zext.b	a4,a5
    for (int i = 0; i < 8; i++) {
8000019c:	fc081ae3          	bnez	a6,80000170 <spi_flashio+0x11c>
        QSPI0->IO = QSPI_IO_CSb;
800001a0:	02000793          	li	a5,32
800001a4:	00f68023          	sb	a5,0(a3)
    QSPI0->IO = 0;
800001a8:	00068023          	sb	zero,0(a3)
    while (length) {
800001ac:	ec0592e3          	bnez	a1,80000070 <spi_flashio+0x1c>
    QSPI0->IO = QSPI_IO_CSb;
800001b0:	00f68023          	sb	a5,0(a3)
    if (wren) {
800001b4:	f15ff06f          	j	800000c8 <spi_flashio+0x74>
    QSPI0->IO = QSPI_IO_CSb;
800001b8:	02000793          	li	a5,32
800001bc:	00f68023          	sb	a5,0(a3)
    if (wren) {
800001c0:	f99ff06f          	j	80000158 <spi_flashio+0x104>

Disassembly of section .text.startup.main:

800001c4 <main>:
#define FW_WAIT_MAXCNT  ((int)(400000 / 0.8))
#define CLK_FREQ        25175000
#define UART_BAUD       115200

int main()
{
800001c4:	ec010113          	addi	sp,sp,-320
800001c8:	12112e23          	sw	ra,316(sp)
800001cc:	12812c23          	sw	s0,312(sp)
800001d0:	12912a23          	sw	s1,308(sp)
800001d4:	13212823          	sw	s2,304(sp)
800001d8:	13312623          	sw	s3,300(sp)
800001dc:	13412423          	sw	s4,296(sp)
800001e0:	13512223          	sw	s5,292(sp)
800001e4:	13612023          	sw	s6,288(sp)
800001e8:	11712e23          	sw	s7,284(sp)
    FLASH_BUF flash_buffer;
    uint8_t instr;
    int buflen;
    int waitcnt;

    UART0->CLKDIV = CLK_FREQ / UART_BAUD - 2;
800001ec:	830006b7          	lui	a3,0x83000
800001f0:	0d800713          	li	a4,216
800001f4:	0007a7b7          	lui	a5,0x7a
800001f8:	00e6a223          	sw	a4,4(a3) # 83000004 <__global_pointer$+0x2fff46c>
800001fc:	12078793          	addi	a5,a5,288 # 7a120 <_stack_size+0x79f20>
    
    for (waitcnt = 0; waitcnt < FW_WAIT_MAXCNT; waitcnt++) {
        if (UART0->DATA == 0x55) {
80000200:	05500613          	li	a2,85
80000204:	0080006f          	j	8000020c <main+0x48>
    for (waitcnt = 0; waitcnt < FW_WAIT_MAXCNT; waitcnt++) {
80000208:	18078063          	beqz	a5,80000388 <main+0x1c4>
        if (UART0->DATA == 0x55) {
8000020c:	0006a703          	lw	a4,0(a3)
    for (waitcnt = 0; waitcnt < FW_WAIT_MAXCNT; waitcnt++) {
80000210:	fff78793          	addi	a5,a5,-1
        if (UART0->DATA == 0x55) {
80000214:	fec71ae3          	bne	a4,a2,80000208 <main+0x44>
    UART0->DATA = wdata;
80000218:	05600793          	li	a5,86
8000021c:	00f6a023          	sw	a5,0(a3)
            uart_putchar(0x56);
            break;
        }
    }

    if (waitcnt == FW_WAIT_MAXCNT) {
80000220:	00c10a93          	addi	s5,sp,12
            uart_putchar(0x11);
            
            buflen = uart_getchar() + 1;

            uint8_t chksum = 0;
            for (int i = 0; i < buflen; i++) {
80000224:	ffb00b93          	li	s7,-5
80000228:	415b8bb3          	sub	s7,s7,s5
        rdata = UART0->DATA;
8000022c:	83000437          	lui	s0,0x83000
        switch(instr) {
80000230:	04000b13          	li	s6,64
    UART0->DATA = wdata;
80000234:	04100a13          	li	s4,65
            // page length saved from last WBUF
            // Host:  0x40        addr2-0
            // Reply:       0x41           [program] 0x42
            uart_putchar(0x41);

            flash_buffer.instr = QSPI_FLASH_PP;
80000238:	00200993          	li	s3,2
    UART0->DATA = wdata;
8000023c:	04200913          	li	s2,66
        rdata = UART0->DATA;
80000240:	00042783          	lw	a5,0(s0) # 83000000 <__global_pointer$+0x2fff468>
    } while (rdata < 0);
80000244:	fe07cee3          	bltz	a5,80000240 <main+0x7c>
        switch(instr) {
80000248:	0ff7f793          	zext.b	a5,a5
8000024c:	0d678c63          	beq	a5,s6,80000324 <main+0x160>
80000250:	04fb6c63          	bltu	s6,a5,800002a8 <main+0xe4>
80000254:	01000713          	li	a4,16
80000258:	06e78a63          	beq	a5,a4,800002cc <main+0x108>
8000025c:	03000713          	li	a4,48
80000260:	fee790e3          	bne	a5,a4,80000240 <main+0x7c>
    UART0->DATA = wdata;
80000264:	03100793          	li	a5,49
80000268:	00f42023          	sw	a5,0(s0)
            flash_buffer.instr = QSPI_FLASH_SE;
8000026c:	02000793          	li	a5,32
80000270:	00f10623          	sb	a5,12(sp)
        rdata = UART0->DATA;
80000274:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
80000278:	fe07cee3          	bltz	a5,80000274 <main+0xb0>
    return rdata;
8000027c:	00f106a3          	sb	a5,13(sp)
        rdata = UART0->DATA;
80000280:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
80000284:	fe07cee3          	bltz	a5,80000280 <main+0xbc>
    return rdata;
80000288:	00f10723          	sb	a5,14(sp)
        rdata = UART0->DATA;
8000028c:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
80000290:	fe07cee3          	bltz	a5,8000028c <main+0xc8>
    return rdata;
80000294:	00f107a3          	sb	a5,15(sp)
            if (buflen) {
80000298:	0c049e63          	bnez	s1,80000374 <main+0x1b0>
    UART0->DATA = wdata;
8000029c:	03200793          	li	a5,50
800002a0:	00f42023          	sw	a5,0(s0)
}
800002a4:	f9dff06f          	j	80000240 <main+0x7c>
        switch(instr) {
800002a8:	05500713          	li	a4,85
800002ac:	06e78663          	beq	a5,a4,80000318 <main+0x154>
800002b0:	0f000713          	li	a4,240
800002b4:	f8e796e3          	bne	a5,a4,80000240 <main+0x7c>
    UART0->DATA = wdata;
800002b8:	0f100713          	li	a4,241
            // Reply:       0xF1 
            uart_putchar(0xF1);
            
            // Jump to reset vector
            void (*rst_vec)(void) = (void (*)(void))(0x80000000);
            rst_vec();
800002bc:	800007b7          	lui	a5,0x80000
    UART0->DATA = wdata;
800002c0:	00e42023          	sw	a4,0(s0)
            rst_vec();
800002c4:	000780e7          	jalr	a5 # 80000000 <crtStart>
            break;
800002c8:	f79ff06f          	j	80000240 <main+0x7c>
    UART0->DATA = wdata;
800002cc:	01100793          	li	a5,17
800002d0:	00f42023          	sw	a5,0(s0)
        rdata = UART0->DATA;
800002d4:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
800002d8:	fe07cee3          	bltz	a5,800002d4 <main+0x110>
            buflen = uart_getchar() + 1;
800002dc:	0ff7f613          	zext.b	a2,a5
800002e0:	00160493          	addi	s1,a2,1
            for (int i = 0; i < buflen; i++) {
800002e4:	01010693          	addi	a3,sp,16
            uint8_t chksum = 0;
800002e8:	00000713          	li	a4,0
        rdata = UART0->DATA;
800002ec:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
800002f0:	fe07cee3          	bltz	a5,800002ec <main+0x128>
    return rdata;
800002f4:	0ff7f793          	zext.b	a5,a5
                flash_buffer.data_buf[i] = rdata;
800002f8:	00f68023          	sb	a5,0(a3)
            for (int i = 0; i < buflen; i++) {
800002fc:	00168693          	addi	a3,a3,1
                chksum += rdata;
80000300:	00e78733          	add	a4,a5,a4
            for (int i = 0; i < buflen; i++) {
80000304:	00db87b3          	add	a5,s7,a3
                chksum += rdata;
80000308:	0ff77713          	zext.b	a4,a4
            for (int i = 0; i < buflen; i++) {
8000030c:	fec7c0e3          	blt	a5,a2,800002ec <main+0x128>
    UART0->DATA = wdata;
80000310:	00e42023          	sw	a4,0(s0)
}
80000314:	f2dff06f          	j	80000240 <main+0x7c>
    UART0->DATA = wdata;
80000318:	05600793          	li	a5,86
8000031c:	00f42023          	sw	a5,0(s0)
}
80000320:	f21ff06f          	j	80000240 <main+0x7c>
    UART0->DATA = wdata;
80000324:	01442023          	sw	s4,0(s0)
            flash_buffer.instr = QSPI_FLASH_PP;
80000328:	01310623          	sb	s3,12(sp)
        rdata = UART0->DATA;
8000032c:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
80000330:	fe07cee3          	bltz	a5,8000032c <main+0x168>
    return rdata;
80000334:	00f106a3          	sb	a5,13(sp)
        rdata = UART0->DATA;
80000338:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
8000033c:	fe07cee3          	bltz	a5,80000338 <main+0x174>
    return rdata;
80000340:	00f10723          	sb	a5,14(sp)
        rdata = UART0->DATA;
80000344:	00042783          	lw	a5,0(s0)
    } while (rdata < 0);
80000348:	fe07cee3          	bltz	a5,80000344 <main+0x180>
    return rdata;
8000034c:	00f107a3          	sb	a5,15(sp)
            if (buflen) {
80000350:	00049663          	bnez	s1,8000035c <main+0x198>
    UART0->DATA = wdata;
80000354:	01242023          	sw	s2,0(s0)
}
80000358:	ee9ff06f          	j	80000240 <main+0x7c>
                spi_flashio( (void *)&flash_buffer, 4+buflen, FLASHIO_REQWREN);
8000035c:	00100613          	li	a2,1
80000360:	00448593          	addi	a1,s1,4
80000364:	000a8513          	mv	a0,s5
80000368:	cedff0ef          	jal	80000054 <spi_flashio>
    UART0->DATA = wdata;
8000036c:	01242023          	sw	s2,0(s0)
            break;
80000370:	ed1ff06f          	j	80000240 <main+0x7c>
                spi_flashio( (void *)&flash_buffer, 4, FLASHIO_REQWREN);
80000374:	00100613          	li	a2,1
80000378:	00400593          	li	a1,4
8000037c:	000a8513          	mv	a0,s5
80000380:	cd5ff0ef          	jal	80000054 <spi_flashio>
80000384:	f19ff06f          	j	8000029c <main+0xd8>
        flash_vec();
80000388:	001007b7          	lui	a5,0x100
8000038c:	000780e7          	jalr	a5 # 100000 <_stack_size+0xffe00>
80000390:	e91ff06f          	j	80000220 <main+0x5c>
