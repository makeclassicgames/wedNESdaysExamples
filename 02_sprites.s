PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007
PPUSCROLL = $2005
OAMADDR   = $2003
OAMDMA    = $4014

oambuffer = $0200


*=$0000
.asc "NES"
.byt $1a,$02,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
*=$8000
_main:
.(

  ; Cargar las paletas en PPU $3F10 (paletas de sprites)
  LDA PPUSTATUS
  LDA #$3F
  STA PPUADDR
  LDA #$10
  STA PPUADDR
  LDA #$31 ; Celeste claro
  STA PPUDATA
  LDA #$0F ; Negro
  STA PPUDATA
  LDA #$26 ; Rosa
  STA PPUDATA
  LDA #$27 ; Naranja
  STA PPUDATA
  
  LDA #100
  STA $0200
  LDA #1
  STA $0201
  LDA #0
  STA $0202
  LDA #128
  STA $0203
  
  
  ; Configurar PPUCTRL
;  0 1 Base nametable address (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
;  2   VRAM address increment per CPU read/write of PPUDATA (0= add 1, going across; 1= add 32, going down)
;  3   Sprite pattern table address for 8x8 sprites (0= $0000; 1= $1000; ignored in 8x16 mode)
;  4   Background pattern table address (0= $0000; 1= $1000)
;  5   Sprite size (0= 8x8 pixels; 1= 8x16 pixels – see PPU OAM#Byte 1)
;  6   PPU master/slave select (0= read backdrop from EXT pins; 1= output color on EXT pins)
;  7   Vblank NMI enable (0= off, 1= on)
  LDA #%10000000
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
  LDA #%00010110
  STA PPUMASK

  
.)








_nmi_handler:
.(
  PHA

  ; Copy OAM cache
  LDA #<oambuffer
  STA OAMADDR
  LDA #>oambuffer
  STA OAMDMA

  ; Set Background scroll
  LDA #0
  STA PPUSCROLL
  LDA #0
  STA PPUSCROLL
  

  PLA
  RTI
.)

_reset_handler:
.(
  SEI
  CLD
  LDX #$40
  STX $4017
  LDX #$FF
  TXS
  LDX #$0
  STX PPUCTRL
  STX PPUMASK
  STX $4010
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait
vblankwait2:
  BIT $2002
  BPL vblankwait2
  JSR _main
  LDA #$1E
  STA PPUMASK
  end: JMP end
.)
_irq_handler:
  RTI

; VECTORS
.dsb $fffa-*, $ff
.word _nmi_handler ; NMI
.word _reset_handler ; RESET
.word _irq_handler ; IRQ

;=== FIRST TILES BANK (4K) ===
*=$0000
; Tile 0, all with color zero
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
; Tile 1
.byt $28,$3C,$42,$81,$81,$C3,$42,$3C,$00,$00,$00,$24,$00,$5A,$00,$00,
.dsb $1000-*, $00

;=== SECOND TILES BANK (4K) ===
*=$0000
.dsb $1000-*, $00

