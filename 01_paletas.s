PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007

*=$0000
.asc "NES"
.byt $1a,$02,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
*=$8000
_main:
.(


  ; =====================================
  ; PRIMER EJEMPLO 
  ; =====================================
  LDA PPUSTATUS
  LDA #$3F
  STA PPUADDR
  LDA #$00
  STA PPUADDR
  ; Enviar los codigos de color a la PPU
  LDA #$01 ; Azul
  STA PPUDATA
  LDA #$14 ; Violeta
  STA PPUDATA
  LDA #$16 ; Rojo
  STA PPUDATA
  LDA #$29 ; Verde
  STA PPUDATA
  
  
  ; =====================================


  
.)  
RTS
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
_nmi_handler:
  RTI
.dsb $fffa-*, $ff
.word _nmi_handler ; NMI
.word _reset_handler ; RESET
.word _irq_handler ; IRQ
*=$0000
.dsb $2000-*, $00
