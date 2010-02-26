#
#  $Id: sdl_gfx.pas,v 1.3 2007/05/29 21:31:04 savage Exp $
#
#
#
#  $Log: sdl_gfx.pas,v $
#  Revision 1.3  2007/05/29 21:31:04  savage
#  Changes as suggested by Almindor for 64bit compatibility.
#
#  Revision 1.2  2007/05/20 20:30:18  savage
#  Initial Changes to Handle 64 Bits
#
#  Revision 1.1  2005/01/03 19:08:32  savage
#  Header for the SDL_Gfx library.
#
#
#
#

import 
  sdl

when defined(windows): 
  const 
    gfxLibName = "SDL_gfx.dll"
elif defined(macosx): 
  const 
    gfxLibName = "libSDL_gfx.dylib"
else: 
  const 
    gfxLibName = "libSDL_gfx.so"
const                         # Some rates in Hz
  FPS_UPPER_LIMIT* = 200
  FPS_LOWER_LIMIT* = 1
  FPS_DEFAULT* = 30           # ---- Defines
  SMOOTHING_OFF* = 0
  SMOOTHING_ON* = 1

type 
  PFPSmanager* = ptr TFPSmanager
  TFPSmanager*{.final.} = object  # ---- Structures
    framecount*: Uint32
    rateticks*: float32
    lastticks*: Uint32
    rate*: Uint32

  PColorRGBA* = ptr TColorRGBA
  TColorRGBA*{.final.} = object 
    r*: Uint8
    g*: Uint8
    b*: Uint8
    a*: Uint8

  PColorY* = ptr TColorY
  TColorY*{.final.} = object  #
                              #
                              # SDL_framerate: framerate manager
                              #
                              # LGPL (c) A. Schiffler
                              #
                              #
    y*: Uint8


proc initFramerate*(manager: PFPSmanager){.cdecl, importc: "SDL_initFramerate", 
    dynlib: gfxLibName.}
proc setFramerate*(manager: PFPSmanager, rate: int): int{.cdecl, 
    importc: "SDL_setFramerate", dynlib: gfxLibName.}
proc getFramerate*(manager: PFPSmanager): int{.cdecl, 
    importc: "SDL_getFramerate", dynlib: gfxLibName.}
proc framerateDelay*(manager: PFPSmanager){.cdecl, 
    importc: "SDL_framerateDelay", dynlib: gfxLibName.}
  #
  #
  # SDL_gfxPrimitives: graphics primitives for SDL
  #
  # LGPL (c) A. Schiffler
  #
  #
  # Note: all ___Color routines expect the color to be in format 0xRRGGBBAA 
  # Pixel 
proc pixelColor*(dst: PSurface, x: Sint16, y: Sint16, color: Uint32): int{.
    cdecl, importc: "pixelColor", dynlib: gfxLibName.}
proc pixelRGBA*(dst: PSurface, x: Sint16, y: Sint16, r: Uint8, g: Uint8, 
                b: Uint8, a: Uint8): int{.cdecl, importc: "pixelRGBA", 
    dynlib: gfxLibName.}
  # Horizontal line 
proc hlineColor*(dst: PSurface, x1: Sint16, x2: Sint16, y: Sint16, color: Uint32): int{.
    cdecl, importc: "hlineColor", dynlib: gfxLibName.}
proc hlineRGBA*(dst: PSurface, x1: Sint16, x2: Sint16, y: Sint16, r: Uint8, 
                g: Uint8, b: Uint8, a: Uint8): int{.cdecl, importc: "hlineRGBA", 
    dynlib: gfxLibName.}
  # Vertical line 
proc vlineColor*(dst: PSurface, x: Sint16, y1: Sint16, y2: Sint16, color: Uint32): int{.
    cdecl, importc: "vlineColor", dynlib: gfxLibName.}
proc vlineRGBA*(dst: PSurface, x: Sint16, y1: Sint16, y2: Sint16, r: Uint8, 
                g: Uint8, b: Uint8, a: Uint8): int{.cdecl, importc: "vlineRGBA", 
    dynlib: gfxLibName.}
  # Rectangle 
proc rectangleColor*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, 
                     y2: Sint16, color: Uint32): int{.cdecl, 
    importc: "rectangleColor", dynlib: gfxLibName.}
proc rectangleRGBA*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, 
                    y2: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc: "rectangleRGBA", dynlib: gfxLibName.}
  # Filled rectangle (Box) 
proc boxColor*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
               color: Uint32): int{.cdecl, importc: "boxColor", 
                                    dynlib: gfxLibName.}
proc boxRGBA*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
              r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "boxRGBA", dynlib: gfxLibName.}
  # Line 
proc lineColor*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
                color: Uint32): int{.cdecl, importc: "lineColor", 
                                     dynlib: gfxLibName.}
proc lineRGBA*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
               r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "lineRGBA", dynlib: gfxLibName.}
  # AA Line 
proc aalineColor*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
                  color: Uint32): int{.cdecl, importc: "aalineColor", 
                                       dynlib: gfxLibName.}
proc aalineRGBA*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
                 r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "aalineRGBA", dynlib: gfxLibName.}
  # Circle 
proc circleColor*(dst: PSurface, x: Sint16, y: Sint16, r: Sint16, color: Uint32): int{.
    cdecl, importc: "circleColor", dynlib: gfxLibName.}
proc circleRGBA*(dst: PSurface, x: Sint16, y: Sint16, rad: Sint16, r: Uint8, 
                 g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "circleRGBA", dynlib: gfxLibName.}
  # AA Circle 
proc aacircleColor*(dst: PSurface, x: Sint16, y: Sint16, r: Sint16, 
                    color: Uint32): int{.cdecl, importc: "aacircleColor", 
    dynlib: gfxLibName.}
proc aacircleRGBA*(dst: PSurface, x: Sint16, y: Sint16, rad: Sint16, r: Uint8, 
                   g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "aacircleRGBA", dynlib: gfxLibName.}
  # Filled Circle 
proc filledCircleColor*(dst: PSurface, x: Sint16, y: Sint16, r: Sint16, 
                        color: Uint32): int{.cdecl, 
    importc: "filledCircleColor", dynlib: gfxLibName.}
proc filledCircleRGBA*(dst: PSurface, x: Sint16, y: Sint16, rad: Sint16, 
                       r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "filledCircleRGBA", dynlib: gfxLibName.}
  # Ellipse 
proc ellipseColor*(dst: PSurface, x: Sint16, y: Sint16, rx: Sint16, ry: Sint16, 
                   color: Uint32): int{.cdecl, importc: "ellipseColor", 
                                        dynlib: gfxLibName.}
proc ellipseRGBA*(dst: PSurface, x: Sint16, y: Sint16, rx: Sint16, ry: Sint16, 
                  r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "ellipseRGBA", dynlib: gfxLibName.}
  # AA Ellipse 
proc aaellipseColor*(dst: PSurface, xc: Sint16, yc: Sint16, rx: Sint16, 
                     ry: Sint16, color: Uint32): int{.cdecl, 
    importc: "aaellipseColor", dynlib: gfxLibName.}
proc aaellipseRGBA*(dst: PSurface, x: Sint16, y: Sint16, rx: Sint16, ry: Sint16, 
                    r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "aaellipseRGBA", dynlib: gfxLibName.}
  # Filled Ellipse 
proc filledEllipseColor*(dst: PSurface, x: Sint16, y: Sint16, rx: Sint16, 
                         ry: Sint16, color: Uint32): int{.cdecl, 
    importc: "filledEllipseColor", dynlib: gfxLibName.}
proc filledEllipseRGBA*(dst: PSurface, x: Sint16, y: Sint16, rx: Sint16, 
                        ry: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc: "filledEllipseRGBA", dynlib: gfxLibName.}
  # Pie
proc pieColor*(dst: PSurface, x: Sint16, y: Sint16, rad: Sint16, start: Sint16, 
               finish: Sint16, color: Uint32): int{.cdecl, importc: "pieColor", 
    dynlib: gfxLibName.}
proc pieRGBA*(dst: PSurface, x: Sint16, y: Sint16, rad: Sint16, start: Sint16, 
              finish: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc: "pieRGBA", dynlib: gfxLibName.}
  # Filled Pie
proc filledPieColor*(dst: PSurface, x: Sint16, y: Sint16, rad: Sint16, 
                     start: Sint16, finish: Sint16, color: Uint32): int{.cdecl, 
    importc: "filledPieColor", dynlib: gfxLibName.}
proc filledPieRGBA*(dst: PSurface, x: Sint16, y: Sint16, rad: Sint16, 
                    start: Sint16, finish: Sint16, r: Uint8, g: Uint8, b: Uint8, 
                    a: Uint8): int{.cdecl, importc: "filledPieRGBA", 
                                    dynlib: gfxLibName.}
  # Trigon
proc trigonColor*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
                  x3: Sint16, y3: Sint16, color: Uint32): int{.cdecl, 
    importc: "trigonColor", dynlib: gfxLibName.}
proc trigonRGBA*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
                 x3: Sint16, y3: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc: "trigonRGBA", dynlib: gfxLibName.}
  # AA-Trigon
proc aatrigonColor*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, 
                    y2: Sint16, x3: Sint16, y3: Sint16, color: Uint32): int{.
    cdecl, importc: "aatrigonColor", dynlib: gfxLibName.}
proc aatrigonRGBA*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, 
                   y2: Sint16, x3: Sint16, y3: Sint16, r: Uint8, g: Uint8, 
                   b: Uint8, a: Uint8): int{.cdecl, importc: "aatrigonRGBA", 
    dynlib: gfxLibName.}
  # Filled Trigon
proc filledTrigonColor*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, 
                        y2: Sint16, x3: Sint16, y3: Sint16, color: Uint32): int{.
    cdecl, importc: "filledTrigonColor", dynlib: gfxLibName.}
proc filledTrigonRGBA*(dst: PSurface, x1: Sint16, y1: Sint16, x2: Sint16, 
                       y2: Sint16, x3: Sint16, y3: Sint16, r: Uint8, g: Uint8, 
                       b: Uint8, a: Uint8): int{.cdecl, 
    importc: "filledTrigonRGBA", dynlib: gfxLibName.}
  # Polygon
proc polygonColor*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, 
                   color: Uint32): int{.cdecl, importc: "polygonColor", 
                                        dynlib: gfxLibName.}
proc polygonRGBA*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, r: Uint8, 
                  g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "polygonRGBA", dynlib: gfxLibName.}
  # AA-Polygon
proc aapolygonColor*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, 
                     color: Uint32): int{.cdecl, importc: "aapolygonColor", 
    dynlib: gfxLibName.}
proc aapolygonRGBA*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, r: Uint8, 
                    g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "aapolygonRGBA", dynlib: gfxLibName.}
  # Filled Polygon
proc filledPolygonColor*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, 
                         color: Uint32): int{.cdecl, 
    importc: "filledPolygonColor", dynlib: gfxLibName.}
proc filledPolygonRGBA*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, 
                        r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "filledPolygonRGBA", dynlib: gfxLibName.}
  # Bezier
  # s = number of steps
proc bezierColor*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, s: int, 
                  color: Uint32): int{.cdecl, importc: "bezierColor", 
                                       dynlib: gfxLibName.}
proc bezierRGBA*(dst: PSurface, vx: PSint16, vy: PSint16, n: int, s: int, 
                 r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "bezierRGBA", dynlib: gfxLibName.}
  # Characters/Strings
proc characterColor*(dst: PSurface, x: Sint16, y: Sint16, c: char, color: Uint32): int{.
    cdecl, importc: "characterColor", dynlib: gfxLibName.}
proc characterRGBA*(dst: PSurface, x: Sint16, y: Sint16, c: char, r: Uint8, 
                    g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "characterRGBA", dynlib: gfxLibName.}
proc stringColor*(dst: PSurface, x: Sint16, y: Sint16, c: cstring, color: Uint32): int{.
    cdecl, importc: "stringColor", dynlib: gfxLibName.}
proc stringRGBA*(dst: PSurface, x: Sint16, y: Sint16, c: cstring, r: Uint8, 
                 g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc: "stringRGBA", dynlib: gfxLibName.}
proc gfxPrimitivesSetFont*(fontdata: Pointer, cw: int, ch: int){.cdecl, 
    importc: "gfxPrimitivesSetFont", dynlib: gfxLibName.}
  #
  #
  # SDL_imageFilter - bytes-image "filter" routines
  # (uses inline x86 MMX optimizations if available)
  #
  # LGPL (c) A. Schiffler
  #
  #
  # Comments:                                                                           
  #  1.) MMX functions work best if all data blocks are aligned on a 32 bytes boundary. 
  #  2.) Data that is not within an 8 byte boundary is processed using the C routine.   
  #  3.) Convolution routines do not have C routines at this time.                      
  # Detect MMX capability in CPU
proc imageFilterMMXdetect*(): int{.cdecl, importc: "SDL_imageFilterMMXdetect", 
                                   dynlib: gfxLibName.}
  # Force use of MMX off (or turn possible use back on)
proc imageFilterMMXoff*(){.cdecl, importc: "SDL_imageFilterMMXoff", 
                           dynlib: gfxLibName.}
proc imageFilterMMXon*(){.cdecl, importc: "SDL_imageFilterMMXon", 
                          dynlib: gfxLibName.}
  #
  # All routines return:
  #   0   OK
  #  -1   Error (internal error, parameter error)
  #
  #  SDL_imageFilterAdd: D = saturation255(S1 + S2)
proc imageFilterAdd*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterAdd", dynlib: gfxLibName.}
  #  SDL_imageFilterMean: D = S1/2 + S2/2
proc imageFilterMean*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterMean", dynlib: gfxLibName.}
  #  SDL_imageFilterSub: D = saturation0(S1 - S2)
proc imageFilterSub*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterSub", dynlib: gfxLibName.}
  #  SDL_imageFilterAbsDiff: D = | S1 - S2 |
proc imageFilterAbsDiff*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterAbsDiff", dynlib: gfxLibName.}
  #  SDL_imageFilterMult: D = saturation(S1 * S2)
proc imageFilterMult*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterMult", dynlib: gfxLibName.}
  #  SDL_imageFilterMultNor: D = S1 * S2   (non-MMX)
proc imageFilterMultNor*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterMultNor", dynlib: gfxLibName.}
  #  SDL_imageFilterMultDivby2: D = saturation255(S1/2 * S2)
proc imageFilterMultDivby2*(Src1: cstring, Src2: cstring, Dest: cstring, 
                            len: int): int{.cdecl, 
    importc: "SDL_imageFilterMultDivby2", dynlib: gfxLibName.}
  #  SDL_imageFilterMultDivby4: D = saturation255(S1/2 * S2/2)
proc imageFilterMultDivby4*(Src1: cstring, Src2: cstring, Dest: cstring, 
                            len: int): int{.cdecl, 
    importc: "SDL_imageFilterMultDivby4", dynlib: gfxLibName.}
  #  SDL_imageFilterBitAnd: D = S1 & S2
proc imageFilterBitAnd*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterBitAnd", dynlib: gfxLibName.}
  #  SDL_imageFilterBitOr: D = S1 | S2
proc imageFilterBitOr*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterBitOr", dynlib: gfxLibName.}
  #  SDL_imageFilterDiv: D = S1 / S2   (non-MMX)
proc imageFilterDiv*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterDiv", dynlib: gfxLibName.}
  #  SDL_imageFilterBitNegation: D = !S
proc imageFilterBitNegation*(Src1: cstring, Dest: cstring, len: int): int{.
    cdecl, importc: "SDL_imageFilterBitNegation", dynlib: gfxLibName.}
  #  SDL_imageFilterAddByte: D = saturation255(S + C)
proc imageFilterAddByte*(Src1: cstring, Dest: cstring, len: int, C: char): int{.
    cdecl, importc: "SDL_imageFilterAddByte", dynlib: gfxLibName.}
  #  SDL_imageFilterAddUint: D = saturation255(S + (uint)C)
proc imageFilterAddUint*(Src1: cstring, Dest: cstring, len: int, C: int): int{.
    cdecl, importc: "SDL_imageFilterAddUint", dynlib: gfxLibName.}
  #  SDL_imageFilterAddByteToHalf: D = saturation255(S/2 + C)
proc imageFilterAddByteToHalf*(Src1: cstring, Dest: cstring, len: int, C: char): int{.
    cdecl, importc: "SDL_imageFilterAddByteToHalf", dynlib: gfxLibName.}
  #  SDL_imageFilterSubByte: D = saturation0(S - C)
proc imageFilterSubByte*(Src1: cstring, Dest: cstring, len: int, C: char): int{.
    cdecl, importc: "SDL_imageFilterSubByte", dynlib: gfxLibName.}
  #  SDL_imageFilterSubUint: D = saturation0(S - (uint)C)
proc imageFilterSubUint*(Src1: cstring, Dest: cstring, len: int, C: int): int{.
    cdecl, importc: "SDL_imageFilterSubUint", dynlib: gfxLibName.}
  #  SDL_imageFilterShiftRight: D = saturation0(S >> N)
proc imageFilterShiftRight*(Src1: cstring, Dest: cstring, len: int, N: char): int{.
    cdecl, importc: "SDL_imageFilterShiftRight", dynlib: gfxLibName.}
  #  SDL_imageFilterShiftRightUint: D = saturation0((uint)S >> N)
proc imageFilterShiftRightUint*(Src1: cstring, Dest: cstring, len: int, N: char): int{.
    cdecl, importc: "SDL_imageFilterShiftRightUint", dynlib: gfxLibName.}
  #  SDL_imageFilterMultByByte: D = saturation255(S * C)
proc imageFilterMultByByte*(Src1: cstring, Dest: cstring, len: int, C: char): int{.
    cdecl, importc: "SDL_imageFilterMultByByte", dynlib: gfxLibName.}
  #  SDL_imageFilterShiftRightAndMultByByte: D = saturation255((S >> N) * C)
proc imageFilterShiftRightAndMultByByte*(Src1: cstring, Dest: cstring, len: int, 
    N: char, C: char): int{.cdecl, 
                            importc: "SDL_imageFilterShiftRightAndMultByByte", 
                            dynlib: gfxLibName.}
  #  SDL_imageFilterShiftLeftByte: D = (S << N)
proc imageFilterShiftLeftByte*(Src1: cstring, Dest: cstring, len: int, N: char): int{.
    cdecl, importc: "SDL_imageFilterShiftLeftByte", dynlib: gfxLibName.}
  #  SDL_imageFilterShiftLeftUint: D = ((uint)S << N)
proc imageFilterShiftLeftUint*(Src1: cstring, Dest: cstring, len: int, N: char): int{.
    cdecl, importc: "SDL_imageFilterShiftLeftUint", dynlib: gfxLibName.}
  #  SDL_imageFilterShiftLeft: D = saturation255(S << N)
proc imageFilterShiftLeft*(Src1: cstring, Dest: cstring, len: int, N: char): int{.
    cdecl, importc: "SDL_imageFilterShiftLeft", dynlib: gfxLibName.}
  #  SDL_imageFilterBinarizeUsingThreshold: D = S >= T ? 255:0
proc imageFilterBinarizeUsingThreshold*(Src1: cstring, Dest: cstring, len: int, 
                                        T: char): int{.cdecl, 
    importc: "SDL_imageFilterBinarizeUsingThreshold", dynlib: gfxLibName.}
  #  SDL_imageFilterClipToRange: D = (S >= Tmin) & (S <= Tmax) 255:0
proc imageFilterClipToRange*(Src1: cstring, Dest: cstring, len: int, Tmin: int8, 
                             Tmax: int8): int{.cdecl, 
    importc: "SDL_imageFilterClipToRange", dynlib: gfxLibName.}
  #  SDL_imageFilterNormalizeLinear: D = saturation255((Nmax - Nmin)/(Cmax - Cmin)*(S - Cmin) + Nmin)
proc imageFilterNormalizeLinear*(Src1: cstring, Dest: cstring, len: int, 
                                 Cmin: int, Cmax: int, Nmin: int, Nmax: int): int{.
    cdecl, importc: "SDL_imageFilterNormalizeLinear", dynlib: gfxLibName.}
  # !!! NO C-ROUTINE FOR THESE FUNCTIONS YET !!! 
  #  SDL_imageFilterConvolveKernel3x3Divide: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel3x3Divide*(Src: cstring, Dest: cstring, rows: int, 
    columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel3x3Divide", dynlib: gfxLibName.}
  #  SDL_imageFilterConvolveKernel5x5Divide: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel5x5Divide*(Src: cstring, Dest: cstring, rows: int, 
    columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel5x5Divide", dynlib: gfxLibName.}
  #  SDL_imageFilterConvolveKernel7x7Divide: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel7x7Divide*(Src: cstring, Dest: cstring, rows: int, 
    columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel7x7Divide", dynlib: gfxLibName.}
  #  SDL_imageFilterConvolveKernel9x9Divide: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel9x9Divide*(Src: cstring, Dest: cstring, rows: int, 
    columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel9x9Divide", dynlib: gfxLibName.}
  #  SDL_imageFilterConvolveKernel3x3ShiftRight: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel3x3ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel3x3ShiftRight", dynlib: gfxLibName.}
  #  SDL_imageFilterConvolveKernel5x5ShiftRight: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel5x5ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel5x5ShiftRight", dynlib: gfxLibName.}
  #  SDL_imageFilterConvolveKernel7x7ShiftRight: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel7x7ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel7x7ShiftRight", dynlib: gfxLibName.}
  #  SDL_imageFilterConvolveKernel9x9ShiftRight: Dij = saturation0and255( ... )
proc imageFilterConvolveKernel9x9ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc: "SDL_imageFilterConvolveKernel9x9ShiftRight", dynlib: gfxLibName.}
  #  SDL_imageFilterSobelX: Dij = saturation255( ... )
proc imageFilterSobelX*(Src: cstring, Dest: cstring, rows: int, columns: int): int{.
    cdecl, importc: "SDL_imageFilterSobelX", dynlib: gfxLibName.}
  #  SDL_imageFilterSobelXShiftRight: Dij = saturation255( ... )
proc imageFilterSobelXShiftRight*(Src: cstring, Dest: cstring, rows: int, 
                                  columns: int, NRightShift: char): int{.cdecl, 
    importc: "SDL_imageFilterSobelXShiftRight", dynlib: gfxLibName.}
  # Align/restore stack to 32 byte boundary -- Functionality untested! --
proc imageFilterAlignStack*(){.cdecl, importc: "SDL_imageFilterAlignStack", 
                               dynlib: gfxLibName.}
proc imageFilterRestoreStack*(){.cdecl, importc: "SDL_imageFilterRestoreStack", 
                                 dynlib: gfxLibName.}
  #
  #
  # SDL_rotozoom - rotozoomer
  #
  # LGPL (c) A. Schiffler
  #
  #
  # 
  # 
  # rotozoomSurface()
  #
  # Rotates and zoomes a 32bit or 8bit 'src' surface to newly created 'dst' surface.
  # 'angle' is the rotation in degrees. 'zoom' a scaling factor. If 'smooth' is 1
  # then the destination 32bit surface is anti-aliased. If the surface is not 8bit
  # or 32bit RGBA/ABGR it will be converted into a 32bit RGBA format on the fly.
  #
  #
proc rotozoomSurface*(src: PSurface, angle: float64, zoom: float64, smooth: int): PSurface{.
    cdecl, importc: "rotozoomSurface", dynlib: gfxLibName.}
proc rotozoomSurfaceXY*(src: PSurface, angle: float64, zoomx: float64, 
                        zoomy: float64, smooth: int): PSurface{.cdecl, 
    importc: "rotozoomSurfaceXY", dynlib: gfxLibName.}
  # Returns the size of the target surface for a rotozoomSurface() call 
proc rotozoomSurfaceSize*(width: int, height: int, angle: float64, 
                          zoom: float64, dstwidth: var int, dstheight: var int){.
    cdecl, importc: "rotozoomSurfaceSize", dynlib: gfxLibName.}
proc rotozoomSurfaceSizeXY*(width: int, height: int, angle: float64, 
                            zoomx: float64, zoomy: float64, dstwidth: var int, 
                            dstheight: var int){.cdecl, 
    importc: "rotozoomSurfaceSizeXY", dynlib: gfxLibName.}
  #
  #
  # zoomSurface()
  #
  # Zoomes a 32bit or 8bit 'src' surface to newly created 'dst' surface.
  # 'zoomx' and 'zoomy' are scaling factors for width and height. If 'smooth' is 1
  # then the destination 32bit surface is anti-aliased. If the surface is not 8bit
  # or 32bit RGBA/ABGR it will be converted into a 32bit RGBA format on the fly.
  #
  #
proc zoomSurface*(src: PSurface, zoomx: float64, zoomy: float64, smooth: int): PSurface{.
    cdecl, importc: "zoomSurface", dynlib: gfxLibName.}
  # Returns the size of the target surface for a zoomSurface() call 
proc zoomSurfaceSize*(width: int, height: int, zoomx: float64, zoomy: float64, 
                      dstwidth: var int, dstheight: var int){.cdecl, 
    importc: "zoomSurfaceSize", dynlib: gfxLibName.}
# implementation
