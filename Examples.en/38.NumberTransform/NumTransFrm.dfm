﻿object NumTransForm: TNumTransForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 10
  Caption = 'number transform. create by.qq600585'
  ClientHeight = 353
  ClientWidth = 936
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 401
    Height = 353
    Lines.Strings = (
      'const'
      '  SInvalidFileFormat: SystemString = '#39'Invalid file format'#39';'
      ''
      '  { -Blowfish lookup tables }'
      ''
      '  bf_P: array [0 .. (BFRounds + 1)] of DWord = ('
      '    $243F6A88, $85A308D3, $13198A2E, $03707344,'
      '    $A4093822, $299F31D0, $082EFA98, $EC4E6C89,'
      '    $452821E6, $38D01377, $BE5466CF, $34E90C6C,'
      '    $C0AC29B7, $C97C50DD, $3F84D5B5, $B5470917,'
      '    $9216D5D9, $8979FB1B);'
      ''
      ''
      'const'
      'tab_coef_num: array[0..3, 0..16, 0..3] of vlc_bits_len ='
      '('
      '  ('
      
        '    (                (%1, 1),                 (%0, 1),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (           (%000101, 6),                (%01, 2),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (         (%00000111, 8),            (%000100, 6),          ' +
        '     (%001, 3),                 (%0, 1)),'
      
        '    (        (%000000111, 9),          (%00000110, 8),          ' +
        ' (%0000101, 7),             (%00011, 5)),'
      
        '    (      (%0000000111, 10),         (%000000110, 9),          ' +
        '(%00000101, 8),            (%000011, 6)),'
      
        '    (     (%00000000111, 11),       (%0000000110, 10),         (' +
        '%000000101, 9),           (%0000100, 7)),'
      
        '    (   (%0000000001111, 13),      (%00000000110, 11),       (%0' +
        '000000101, 10),          (%00000100, 8)),'
      
        '    (   (%0000000001011, 13),    (%0000000001110, 13),      (%00' +
        '000000101, 11),         (%000000100, 9)),'
      
        '    (   (%0000000001000, 13),    (%0000000001010, 13),    (%0000' +
        '000001101, 13),       (%0000000100, 10)),'
      
        '    (  (%00000000001111, 14),   (%00000000001110, 14),    (%0000' +
        '000001001, 13),      (%00000000100, 11)),'
      
        '    (  (%00000000001011, 14),   (%00000000001010, 14),   (%00000' +
        '000001101, 14),    (%0000000001100, 13)),'
      
        '    ( (%000000000001111, 15),  (%000000000001110, 15),   (%00000' +
        '000001001, 14),   (%00000000001100, 14)),'
      
        '    ( (%000000000001011, 15),  (%000000000001010, 15),  (%000000' +
        '000001101, 15),   (%00000000001000, 14)),'
      
        '    ((%0000000000001111, 16),  (%000000000000001, 15),  (%000000' +
        '000001001, 15),  (%000000000001100, 15)),'
      
        '    ((%0000000000001011, 16), (%0000000000001110, 16), (%0000000' +
        '000001101, 16),  (%000000000001000, 15)),'
      
        '    ((%0000000000000111, 16), (%0000000000001010, 16), (%0000000' +
        '000001001, 16), (%0000000000001100, 16)),'
      
        '    ((%0000000000000100, 16), (%0000000000000110, 16), (%0000000' +
        '000000101, 16), (%0000000000001000, 16))'
      '  ),'
      '  ('
      
        '    (               (%11, 2),                 (%0, 1),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (           (%001011, 6),                (%10, 2),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (           (%000111, 6),             (%00111, 5),          ' +
        '     (%011, 3),                 (%0, 1)),'
      
        '    (          (%0000111, 7),            (%001010, 6),          ' +
        '  (%001001, 6),              (%0101, 4)),'
      
        '    (         (%00000111, 8),            (%000110, 6),          ' +
        '  (%000101, 6),              (%0100, 4)),'
      
        '    (         (%00000100, 8),           (%0000110, 7),          ' +
        ' (%0000101, 7),             (%00110, 5)),'
      
        '    (        (%000000111, 9),          (%00000110, 8),          ' +
        '(%00000101, 8),            (%001000, 6)),'
      
        '    (     (%00000001111, 11),         (%000000110, 9),         (' +
        '%000000101, 9),            (%000100, 6)),'
      
        '    (     (%00000001011, 11),      (%00000001110, 11),      (%00' +
        '000001101, 11),           (%0000100, 7)),'
      
        '    (    (%000000001111, 12),      (%00000001010, 11),      (%00' +
        '000001001, 11),         (%000000100, 9)),'
      
        '    (    (%000000001011, 12),     (%000000001110, 12),     (%000' +
        '000001101, 12),      (%00000001100, 11)),'
      
        '    (    (%000000001000, 12),     (%000000001010, 12),     (%000' +
        '000001001, 12),      (%00000001000, 11)),'
      
        '    (   (%0000000001111, 13),    (%0000000001110, 13),    (%0000' +
        '000001101, 13),     (%000000001100, 12)),'
      
        '    (   (%0000000001011, 13),    (%0000000001010, 13),    (%0000' +
        '000001001, 13),    (%0000000001100, 13)),'
      
        '    (   (%0000000000111, 13),   (%00000000001011, 14),    (%0000' +
        '000000110, 13),    (%0000000001000, 13)),'
      
        '    (  (%00000000001001, 14),   (%00000000001000, 14),   (%00000' +
        '000001010, 14),    (%0000000000001, 13)),'
      
        '    (  (%00000000000111, 14),   (%00000000000110, 14),   (%00000' +
        '000000101, 14),   (%00000000000100, 14))'
      '  ),'
      '  ('
      
        '    (             (%1111, 4),                 (%0, 1),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (           (%001111, 6),              (%1110, 4),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (           (%001011, 6),             (%01111, 5),          ' +
        '    (%1101, 4),                 (%0, 1)),'
      
        '    (           (%001000, 6),             (%01100, 5),          ' +
        '   (%01110, 5),              (%1100, 4)),'
      
        '    (          (%0001111, 7),             (%01010, 5),          ' +
        '   (%01011, 5),              (%1011, 4)),'
      
        '    (          (%0001011, 7),             (%01000, 5),          ' +
        '   (%01001, 5),              (%1010, 4)),'
      
        '    (          (%0001001, 7),            (%001110, 6),          ' +
        '  (%001101, 6),              (%1001, 4)),'
      
        '    (          (%0001000, 7),            (%001010, 6),          ' +
        '  (%001001, 6),              (%1000, 4)),'
      
        '    (         (%00001111, 8),           (%0001110, 7),          ' +
        ' (%0001101, 7),             (%01101, 5)),'
      
        '    (         (%00001011, 8),          (%00001110, 8),          ' +
        ' (%0001010, 7),            (%001100, 6)),'
      
        '    (        (%000001111, 9),          (%00001010, 8),          ' +
        '(%00001101, 8),           (%0001100, 7)),'
      
        '    (        (%000001011, 9),         (%000001110, 9),          ' +
        '(%00001001, 8),          (%00001100, 8)),'
      
        '    (        (%000001000, 9),         (%000001010, 9),         (' +
        '%000001101, 9),          (%00001000, 8)),'
      
        '    (      (%0000001101, 10),         (%000000111, 9),         (' +
        '%000001001, 9),         (%000001100, 9)),'
      
        '    (      (%0000001001, 10),       (%0000001100, 10),       (%0' +
        '000001011, 10),       (%0000001010, 10)),'
      
        '    (      (%0000000101, 10),       (%0000001000, 10),       (%0' +
        '000000111, 10),       (%0000000110, 10)),'
      
        '    (      (%0000000001, 10),       (%0000000100, 10),       (%0' +
        '000000011, 10),       (%0000000010, 10))'
      '  ),'
      '  ('
      
        '    (           (%000011, 6),                 (%0, 1),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (           (%000000, 6),            (%000001, 6),          ' +
        '       (%0, 1),                 (%0, 1)),'
      
        '    (           (%000100, 6),            (%000101, 6),          ' +
        '  (%000110, 6),                 (%0, 1)),'
      
        '    (           (%001000, 6),            (%001001, 6),          ' +
        '  (%001010, 6),            (%001011, 6)),'
      
        '    (           (%001100, 6),            (%001101, 6),          ' +
        '  (%001110, 6),            (%001111, 6)),'
      
        '    (           (%010000, 6),            (%010001, 6),          ' +
        '  (%010010, 6),            (%010011, 6)),'
      
        '    (           (%010100, 6),            (%010101, 6),          ' +
        '  (%010110, 6),            (%010111, 6)),'
      
        '    (           (%011000, 6),            (%011001, 6),          ' +
        '  (%011010, 6),            (%011011, 6)),'
      
        '    (           (%011100, 6),            (%011101, 6),          ' +
        '  (%011110, 6),            (%011111, 6)),'
      
        '    (           (%100000, 6),            (%100001, 6),          ' +
        '  (%100010, 6),            (%100011, 6)),'
      
        '    (           (%100100, 6),            (%100101, 6),          ' +
        '  (%100110, 6),            (%100111, 6)),'
      
        '    (           (%101000, 6),            (%101001, 6),          ' +
        '  (%101010, 6),            (%101011, 6)),'
      
        '    (           (%101100, 6),            (%101101, 6),          ' +
        '  (%101110, 6),            (%101111, 6)),'
      
        '    (           (%110000, 6),            (%110001, 6),          ' +
        '  (%110010, 6),            (%110011, 6)),'
      
        '    (           (%110100, 6),            (%110101, 6),          ' +
        '  (%110110, 6),            (%110111, 6)),'
      
        '    (           (%111000, 6),            (%111001, 6),          ' +
        '  (%111010, 6),            (%111011, 6)),'
      
        '    (           (%111100, 6),            (%111101, 6),          ' +
        '  (%111110, 6),            (%111111, 6))'
      '  )'
      ');'
      ''
      '{'
      'separate table for nC == -1 (chroma DC)'
      '3+3 bit code/length'
      '}'
      'tab_coef_num_chroma_dc: array[0..4, 0..3] of vlc_bits_len ='
      '('
      '  (    (%01, 2),        (%0, 1),        (%0, 1),       (%0, 1)),'
      '  ((%000111, 6),        (%1, 1),        (%0, 1),       (%0, 1)),'
      '  ((%000100, 6),   (%000110, 6),      (%001, 3),       (%0, 1)),'
      '  ((%000011, 6),  (%0000011, 7),  (%0000010, 7),  (%000101, 6)),'
      '  ((%000010, 6), (%00000011, 8), (%00000010, 8), (%0000000, 7))'
      ');')
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object Memo2: TMemo
    Left = 535
    Top = 0
    Width = 401
    Height = 353
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object Button1: TButton
    Left = 407
    Top = 24
    Width = 121
    Height = 25
    Caption = 'Binary -> Dec'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 408
    Top = 55
    Width = 121
    Height = 25
    Caption = 'Binary <- Dec'
    TabOrder = 3
    OnClick = Button2Click
  end
end
