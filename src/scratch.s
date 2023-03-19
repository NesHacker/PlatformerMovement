




  ldx HEADING
  lda left_sprite, x
  sta $200 + OAM_TILE
  lda right_sprite, x
  sta $204 + OAM_TILE
 
  rts
  left_sprite:  .byte $80, $82
  right_sprite: .byte $82, $80

















