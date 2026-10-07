; PPU Resgisters
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007
PPUSCROLL = $2005
OAMADDR   = $2003
OAMDMA    = $4014

;Palettes -> PPU memory from $3f00 to $3f20
PPU_BG_PALETTES = $3F00 ; 4 colors in each palette. First one is universal background in all of them.
PPU_FG_PALETTES = $3f10

; PPU Tilemaps
PPU_SCREEN_1_MAP=$2000 ; 960 tiles of 1 byte + 64 bytes attribute table
PPU_SCREEN_2_MAP=$2400
PPU_SCREEN_3_MAP=$2800
PPU_SCREEN_4_MAP=$2C00

; Gamepad ports
PORT1 = $4016
PORT2 = $4017

; Gamepad Buttons
BTN_RIGHT   = %00000001
BTN_LEFT    = %00000010
BTN_DOWN    = %00000100
BTN_UP      = %00001000
BTN_START   = %00010000
BTN_SELECT  = %00100000
BTN_B       = %01000000
BTN_A       = %10000000

; Variables
gamepad1 = $01
gamepad2 = $02
scrollx  = $03
scrolly  = $04
oambuffer = $0200


; === EMULATORS HEADER (16 byte) (https://www.nesdev.org/wiki/INES) ===
*=$0000
.asc "NES"
.byt $1a                      ; Magic string that always begins an iNES header
.byt $02                      ; Number of 16KB PRG-ROM banks
.byt $02                      ; Number of 8KB CHR-ROM banks
.byt %00000001                ; Vertical mirroring (Screens left, right), no save RAM, no mapper
.byt %00000000                ; No special-case flags set, no mapper
.byt $00                      ; No PRG-RAM present
.byt $00                      ; NTSC format
.byt $00,$00,$00,$00,$00,$00  ; Unused padding


; === 32K PRG ROM (https://www.nesdev.org/wiki/NROM) ===
*=$8000

.asc "CODE"
_main:
.(
  ; Reset latch PPUADDR
  LDX PPUSTATUS
  ; Set PPU high address $3F00 to store next value
  LDX #>PPU_BG_PALETTES
  STX PPUADDR
  ; Set PPU low address $3F00 to store next value
  LDX #$00
  STX PPUADDR
  
  ; Send paleta
  LDX #0
  loop_paletas
    LDA paletas,X
    STA PPUDATA
    INX
    CPX #32
  BNE loop_paletas
  
  
  
  ; Set PPU address to nametable 1
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_1_MAP
  STX PPUADDR
  LDX #<PPU_SCREEN_1_MAP
  STX PPUADDR
  ; Send background tiles
  LDX #0
  loop_back1:
    LDA background,X
    STA PPUDATA
    INX
  BNE loop_back1
  loop_back2:
    LDA background+256,X
    STA PPUDATA
    INX
  BNE loop_back2
  loop_back3:
    LDA background+512,X
    STA PPUDATA
    INX
  BNE loop_back3
  loop_back4:
    LDA background+768,X
    STA PPUDATA
    INX
  BNE loop_back4
      
    
  ; Set scroll
  LDA #0
  STA scrollx
  LDA #0
  STA scrolly
  
  ; Load sprites to ram cache
  LDX #0
  loop3:
  LDA sprites,X
  STA $0200,X
  INX
  CPX #32
  BNE loop3
  
  
  ; wait for vblank
  vblankwait:       
  BIT PPUSTATUS
  BPL vblankwait
  
; Configurar PPUCTRL
;  0 1 Base nametable address (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
;  2   VRAM address increment per CPU read/write of PPUDATA (0= add 1, going across; 1= add 32, going down)
;  3   Sprite pattern table address for 8x8 sprites (0= $0000; 1= $1000; ignored in 8x16 mode)
;  4   Background pattern table address (0= $0000; 1= $1000)
;  5   Sprite size (0= 8x8 pixels; 1= 8x16 pixels – see PPU OAM#Byte 1)
;  6   PPU master/slave select (0= read backdrop from EXT pins; 1= output color on EXT pins)
;  7   Vblank NMI enable (0= off, 1= on)
  LDA #%10001000
  STA PPUCTRL
  
; Configurar PPUMASK
;  0  Greyscale mode enable (0 normal color, 1 greyscale)
;  1  Left edge (8px) background enable (0 hide, 1 show)
;  2  Left edge (8px) foreground enable (0 hide, 1 show)
;  3  Background enable
;  4  Foreground enable
;  5  Emphasize red
;  6  Emphasize green
;  7  Emphasize blue
  LDA #%00011110
  STA PPUMASK
  
forever:
  JMP forever
.)
; -- end main method --


_update:
.(
  ; Player 1 up
  LDA gamepad1
  AND #BTN_UP
  BEQ next
  DEC $0200
  DEC $0204
  DEC $0208
  DEC $020C
  next:
  ; Player 1 down
  LDA gamepad1
  AND #BTN_DOWN
  BEQ next2
  INC $0200
  INC $0204
  INC $0208
  INC $020C
  next2:
  
  ; Player 2 up
  LDA gamepad2
  AND #BTN_UP
  BEQ next3
  DEC $0210
  DEC $0214
  DEC $0218
  DEC $021C
  next3:
  ; Player 2 down
  LDA gamepad2
  AND #BTN_DOWN
  BEQ next4
  INC $0210
  INC $0214
  INC $0218
  INC $021C
  next4:
  
  RTS
.)

; === CONSTANTS ===
paletas: 
  .byt $31,$0F,$24,$30, $31,$15,$10,$2D, $31,$0F,$20,$17 ,$31,$09,$19,$0F, ; Fondos
  .byt $31,$16,$28,$0f, $31,$21,$21,$21, $31,$21,$21,$21 ,$31,$21,$21,$21, ; Sprites
  
sprites:
; y tile attr x
.byt 50,1,0,8
.byt 58,2,0,8
.byt 66,3,0,8
.byt 74,4,0,8

.byt 50,1,0,240
.byt 58,2,0,240
.byt 66,3,0,240
.byt 74,4,0,240


background:
.byt $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
.byt $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$06,$07,$08,$09,$0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$0C,$0D,$0E,$0F,$10,$11,$12,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$13,$14,$15,$00,$03,$04,$00,$16,$17,$18,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$19,$1A,$00,$00,$03,$04,$00,$00,$1B,$1C,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$1D,$1E,$00,$00,$03,$04,$00,$00,$1F,$20,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$1D,$21,$00,$00,$03,$04,$00,$00,$22,$20,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$23,$24,$00,$00,$03,$04,$00,$00,$25,$26,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$27,$28,$29,$00,$03,$04,$00,$2A,$2B,$2C,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$2D,$2E,$2F,$30,$31,$32,$33,$34,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$35,$36,$37,$38,$39,$3A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$01,
.byt $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
.byt $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,


.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,

_reset_handler:
.(
  ; Disable interrupts
  SEI
  ; Disable decimal mode
  CLD
  ; Disable audio IRQs
  LDX #$40
  STX $4017
  ; Initialize stack
  LDX #$FF
  TXS
  ; Disable NMI frame trigger bit 7 controls whether or not the PPU will trigger an NMI every frame
  LDX #$0
  STX PPUCTRL
  ; Disable graphics
  STX PPUMASK
  ; Turn off DMC IRQs
  STX $4010
  ; Wait for the PPU to fully boot up
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait
vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP _main
.)

_irq_handler:
  RTI

_nmi_handler:
.(
  PHA

  ; Copy OAM cache
  LDA #<oambuffer
  STA OAMADDR
  LDA #>oambuffer
  STA OAMDMA

  ; Set Background scroll
  LDA scrollx
  STA PPUSCROLL
  LDA scrolly
  STA PPUSCROLL
  LDA #%10001000
  STA PPUCTRL

  ; Latch controllers
  LDA #$01
  STA PORT1
  LDA #$00
  STA PORT1  
  ; Read controller 1
  LDA #%00000001
  STA gamepad1
  loop:
  LDA PORT1
  LSR
  ROL gamepad1
  BCC loop  
  ; Read controller 2
  LDA #%00000001
  STA gamepad2
  loop2:
  LDA PORT2
  LSR
  ROL gamepad2
  BCC loop2
  
  jsr _update

  PLA
  RTI
.)

; === VECTORS ===
.dsb $fffa-*, $ff
.word _nmi_handler ; NMI
.word _reset_handler ; RESET
.word _irq_handler ; IRQ


;=== 4K BACKGROUND CHR (TILES) (256 tiles of 16 bytes) ===
*=$0000

.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00, ; Tile $00,
.byt $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00, ; Tile $01,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF, ; Tile $02,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F, ; Tile $03,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0, ; Tile $04,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$0F,$1F,$7F, ; Tile $05,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1F,$FF,$FF,$FF,$FF,$FF, ; Tile $06,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF, ; Tile $07,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$F0,$FE,$FF,$FF,$FF,$FF,$FF,$FF, ; Tile $08,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$FE,$FF,$FF,$FF,$FF, ; Tile $09,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$E0,$F0,$FC, ; Tile $0A,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$07,$0F,$1F,$3F,$3F,$7F, ; Tile $0B,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$F8, ; Tile $0C,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$F8,$E0,$80,$00,$00,$00, ; Tile $0D,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$0F,$0F,$0F,$0F,$0F,$0F,$0F, ; Tile $0E,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$F1,$F0,$F0,$F0,$F0,$F0,$F0, ; Tile $0F,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$3F,$0F,$03,$01,$00,$00, ; Tile $10,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FE,$FF,$FF,$FF,$FF,$FF,$7F,$3F, ; Tile $11,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C0,$E0,$F0,$F8,$F8,$FC, ; Tile $12,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$03,$07,$07,$0F,$0F, ; Tile $13,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FE,$FC,$FC, ; Tile $14,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$F0,$C0,$80,$80,$00,$00,$00,$00, ; Tile $15,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$1F,$07,$03,$03,$01,$00,$00,$00, ; Tile $16,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FE,$FF,$FF,$FF,$FF,$FF,$7F,$7F, ; Tile $17,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$C0,$E0,$E0, ; Tile $18,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$0F,$1F,$1F,$1F,$3F,$3F,$3F,$3F, ; Tile $19,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$F8,$F0,$F0,$E0,$E0,$E0,$C0,$C0, ; Tile $1A,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$3F,$1F,$1F,$0F,$0F,$0F,$07,$07, ; Tile $1B,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$E0,$F0,$F0,$F0,$F8,$F8,$F8,$F8, ; Tile $1C,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F, ; Tile $1D,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$C0,$80,$80,$80,$80,$00,$00,$00, ; Tile $1E,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$07,$03,$03,$03,$03,$01,$01,$01, ; Tile $1F,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC, ; Tile $20,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80,$80,$C0, ; Tile $21,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$03,$03,$03,$03,$07, ; Tile $22,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$3F,$3F,$3F,$3F,$1F,$1F,$1F,$0F, ; Tile $23,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$C0,$C0,$E0,$E0,$E0,$F0,$F0,$F8, ; Tile $24,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$07,$07,$0F,$0F,$0F,$1F,$1F,$3F, ; Tile $25,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$F8,$F8,$F8,$F8,$F0,$F0,$F0,$E0, ; Tile $26,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$0F,$0F,$07,$07,$03,$01,$01,$00, ; Tile $27,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FC,$FC,$FE,$FF,$FF,$FF,$FF,$FF, ; Tile $28,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$C0,$F0, ; Tile $29,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$03,$07,$1F, ; Tile $2A,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FE, ; Tile $2B,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$E0,$E0,$C0,$C0,$80,$00,$00,$00, ; Tile $2C,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$7F,$3F,$3F,$1F,$0F,$07,$01,$00, ; Tile $2D,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$F8,$FC,$FF,$FF,$FF,$FF,$FF,$FF, ; Tile $2E,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$E0,$F8,$FF,$FF, ; Tile $2F,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$FF, ; Tile $30,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$F0,$F0,$F0,$F0,$F0,$F0,$F1,$FF, ; Tile $31,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$0F,$3F,$FF,$FF, ; Tile $32,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$3F,$7F,$FF,$FF,$FF,$FF,$FF,$FE, ; Tile $33,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FC,$F8,$F8,$F0,$E0,$C0,$00,$00, ; Tile $34,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$7F,$1F,$0F,$03,$00,$00,$00,$00, ; Tile $35,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$1F,$00,$00, ; Tile $36,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0F, ; Tile $37,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$F0, ; Tile $38,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FE,$F0,$00,$00, ; Tile $39,
.byt $00,$00,$00,$00,$00,$00,$00,$00,$FC,$F0,$E0,$80,$00,$00,$00,$00, ; Tile $3A,



; Unused tiles
.dsb $1000-*, $00

;=== 4K SPRITE CHR (TILES) (256 tiles of 16 bytes) ===
*=$0000

; Tile 0, all with color zero
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
; Tile 1
.byt $18,$7E,$FF,$93,$A5,$C9,$93,$A5,$18,$66,$81,$FF,$FF,$FF,$FF,$FF
.byt $C9,$93,$A5,$C9,$93,$A5,$C9,$93,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byt $A5,$C9,$93,$A5,$C9,$93,$A5,$C9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byt $93,$A5,$C9,$93,$A5,$FF,$7E,$18,$FF,$FF,$FF,$FF,$FF,$81,$66,$18


; Unused tiles
.dsb $1000-*, $00
