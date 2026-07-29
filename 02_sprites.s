PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007
PPUSCROLL = $2005
OAMADDR   = $2003
OAMDMA    = $4014


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
    
  ; Cargar sprite
  ; Sprite Y
  LDA #100
  STA $0200
  ; Sprite tile
  LDA #1
  STA $0201
  ; Sprite attr
  LDA #0
  STA $0202
  ; Sprite X
  LDA #128
  STA $0203
  
    ; Cargar sprite
  ; Sprite Y
  LDA #120
  STA $0204
  ; Sprite tile
  LDA #1
  STA $0205
  ; Sprite attr
  LDA #0
  STA $0206
  ; Sprite X
  LDA #130
  STA $0207
  

  LDA #$80
  STA PPUCTRL
  LDA #$16
  STA PPUMASK
  end: JMP end
.)








_nmi_handler:
.(
	
  ; Copy OAM cache
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  
  INC $0203


  
  LDA #$80
  STA PPUCTRL
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

