#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Simple PEG (Parsing expression grammar) matching. Uses no memorization, but
## uses superoperators and symbol inlining to improve performance. Note:
## Matching performance is hopefully competitive with optimized regular
## expression engines.
##
## .. include:: ../doc/pegdocs.txt
##

const
  useUnicode = true ## change this to deactivate proper UTF-8 support

import
  strutils

when useUnicode:
  import unicode

const
  InlineThreshold = 5   ## number of leaves; -1 to disable inlining
  MaxSubpatterns* = 10 ## defines the maximum number of subpatterns that
                       ## can be captured. More subpatterns cannot be captured! 

type
  TPegKind = enum
    pkEmpty,
    pkAny,              ## any character (.)
    pkAnyRune,          ## any Unicode character (_)
    pkNewLine,          ## CR-LF, LF, CR
    pkTerminal,
    pkTerminalIgnoreCase,
    pkTerminalIgnoreStyle,
    pkChar,             ## single character to match
    pkCharChoice,
    pkNonTerminal,
    pkSequence,         ## a b c ... --> Internal DSL: peg(a, b, c)
    pkOrderedChoice,    ## a / b / ... --> Internal DSL: a / b or /[a, b, c]
    pkGreedyRep,        ## a*     --> Internal DSL: *a
                        ## a+     --> (a a*)
    pkGreedyRepChar,    ## x* where x is a single character (superop)
    pkGreedyRepSet,     ## [set]* (superop)
    pkGreedyAny,        ## .* or _* (superop)
    pkOption,           ## a?     --> Internal DSL: ?a
    pkAndPredicate,     ## &a     --> Internal DSL: &a
    pkNotPredicate,     ## !a     --> Internal DSL: !a
    pkCapture,          ## {a}    --> Internal DSL: capture(a)
    pkBackRef,          ## $i     --> Internal DSL: backref(i)
    pkBackRefIgnoreCase,
    pkBackRefIgnoreStyle,
    pkSearch,           ## @a     --> Internal DSL: @a
    pkRule,             ## a <- b
    pkList              ## a, b
  TNonTerminalFlag = enum
    ntDeclared, ntUsed
  TNonTerminal {.final.} = object ## represents a non terminal symbol
    name: string                  ## the name of the symbol
    line: int                     ## line the symbol has been declared/used in
    col: int                      ## column the symbol has been declared/used in
    flags: set[TNonTerminalFlag]  ## the nonterminal's flags
    rule: TNode                   ## the rule that the symbol refers to
  TNode {.final.} = object
    case kind: TPegKind
    of pkEmpty, pkAny, pkAnyRune, pkGreedyAny, pkNewLine: nil
    of pkTerminal, pkTerminalIgnoreCase, pkTerminalIgnoreStyle: term: string
    of pkChar, pkGreedyRepChar: ch: char
    of pkCharChoice, pkGreedyRepSet: charChoice: ref set[char]
    of pkNonTerminal: nt: PNonTerminal
    of pkBackRef..pkBackRefIgnoreStyle: index: range[1..MaxSubpatterns]
    else: sons: seq[TNode]
  PNonTerminal* = ref TNonTerminal
  
  TPeg* = TNode ## type that represents a PEG

proc term*(t: string): TPeg =
  ## constructs a PEG from a terminal string
  if t.len != 1:  
    result.kind = pkTerminal
    result.term = t
  else:
    result.kind = pkChar
    result.ch = t[0]

proc termIgnoreCase*(t: string): TPeg =
  ## constructs a PEG from a terminal string; ignore case for matching
  result.kind = pkTerminalIgnoreCase
  result.term = t

proc termIgnoreStyle*(t: string): TPeg =
  ## constructs a PEG from a terminal string; ignore style for matching
  result.kind = pkTerminalIgnoreStyle
  result.term = t

proc term*(t: char): TPeg =
  ## constructs a PEG from a terminal char
  assert t != '\0'
  result.kind = pkChar
  result.ch = t
  
proc charSet*(s: set[char]): TPeg =
  ## constructs a PEG from a character set `s`
  assert '\0' notin s
  result.kind = pkCharChoice
  new(result.charChoice)
  result.charChoice^ = s

proc len(a: TPeg): int {.inline.} = return a.sons.len
proc add(d: var TPeg, s: TPeg) {.inline.} = add(d.sons, s)

proc addChoice(dest: var TPeg, elem: TPeg) =
  var L = dest.len-1
  if L >= 0 and dest.sons[L].kind == pkCharChoice: 
    case elem.kind
    of pkCharChoice:
      dest.sons[L].charChoice^ = dest.sons[L].charChoice^ + elem.charChoice^
    of pkChar: incl(dest.sons[L].charChoice^, elem.ch)
    else: add(dest, elem)
  else: add(dest, elem)

template multipleOp(k: TPegKind, localOpt: expr) =
  result.kind = k
  result.sons = @[]
  for x in items(a):
    if x.kind == k:
      for y in items(x.sons):
        localOpt(result, y)
    else:
      localOpt(result, x)
  if result.len == 1:
    result = result.sons[0]

proc `/`*(a: openArray[TPeg]): TPeg =
  ## constructs an ordered choice with the PEGs in `a`
  multipleOp(pkOrderedChoice, addChoice)

proc addSequence(dest: var TPeg, elem: TPeg) =
  var L = dest.len-1
  if L >= 0 and dest.sons[L].kind == pkTerminal: 
    case elem.kind
    of pkTerminal: add(dest.sons[L].term, elem.term)
    of pkChar: add(dest.sons[L].term, elem.ch)
    else: add(dest, elem)
  else: add(dest, elem)

proc sequence*(a: openArray[TPeg]): TPeg =
  ## constructs a sequence with all the PEGs from `a`
  multipleOp(pkSequence, addSequence)
 
proc `?`*(a: TPeg): TPeg =
  ## constructs an optional for the PEG `a`
  if a.kind in {pkOption, pkGreedyRep, pkGreedyAny, pkGreedyRepChar,
                pkGreedyRepSet}:
    # a* ?  --> a*
    # a? ?  --> a?
    result = a
  else:
    result.kind = pkOption
    result.sons = @[a]

proc `*`*(a: TPeg): TPeg =
  ## constructs a "greedy repetition" for the PEG `a`
  case a.kind
  of pkGreedyRep, pkGreedyRepChar, pkGreedyRepSet, pkGreedyAny, pkOption:
    assert false
    # produces endless loop!
  of pkChar:
    result.kind = pkGreedyRepChar
    result.ch = a.ch
  of pkCharChoice:
    result.kind = pkGreedyRepSet
    result.charChoice = a.charChoice # copying a reference suffices!
  of pkAny, pkAnyRune:
    result.kind = pkGreedyAny
  else:
    result.kind = pkGreedyRep
    result.sons = @[a]

proc `@`*(a: TPeg): TPeg =
  ## constructs a "search" for the PEG `a`
  result.kind = pkSearch
  result.sons = @[a]
  
when false:
  proc contains(a: TPeg, k: TPegKind): bool =
    if a.kind == k: return true
    case a.kind
    of pkEmpty, pkAny, pkAnyRune, pkGreedyAny, pkNewLine, pkTerminal,
       pkTerminalIgnoreCase, pkTerminalIgnoreStyle, pkChar, pkGreedyRepChar,
       pkCharChoice, pkGreedyRepSet: nil
    of pkNonTerminal: return true
    else:
      for i in 0..a.sons.len-1:
        if contains(a.sons[i], k): return true

proc `+`*(a: TPeg): TPeg =
  ## constructs a "greedy positive repetition" with the PEG `a`
  return sequence(a, *a)
  
proc `&`*(a: TPeg): TPeg =
  ## constructs an "and predicate" with the PEG `a`
  result.kind = pkAndPredicate
  result.sons = @[a]

proc `!`*(a: TPeg): TPeg =
  ## constructs a "not predicate" with the PEG `a`
  result.kind = pkNotPredicate
  result.sons = @[a]

proc any*: TPeg {.inline.} =
  ## constructs the PEG `any character`:idx: (``.``)
  result.kind = pkAny

proc anyRune*: TPeg {.inline.} =
  ## constructs the PEG `any rune`:idx: (``_``)
  result.kind = pkAnyRune

proc newLine*: TPeg {.inline.} =
  ## constructs the PEG `newline`:idx: (``\n``)
  result.kind = pkNewline

proc capture*(a: TPeg): TPeg =
  ## constructs a capture with the PEG `a`
  result.kind = pkCapture
  result.sons = @[a]

proc backref*(index: range[1..MaxSubPatterns]): TPeg = 
  ## constructs a back reference of the given `index`. `index` starts counting
  ## from 1.
  result.kind = pkBackRef
  result.index = index-1

proc backrefIgnoreCase*(index: range[1..MaxSubPatterns]): TPeg = 
  ## constructs a back reference of the given `index`. `index` starts counting
  ## from 1. Ignores case for matching.
  result.kind = pkBackRefIgnoreCase
  result.index = index-1

proc backrefIgnoreStyle*(index: range[1..MaxSubPatterns]): TPeg = 
  ## constructs a back reference of the given `index`. `index` starts counting
  ## from 1. Ignores style for matching.
  result.kind = pkBackRefIgnoreStyle
  result.index = index-1

proc spaceCost(n: TPeg): int =
  case n.kind
  of pkEmpty: nil
  of pkTerminal, pkTerminalIgnoreCase, pkTerminalIgnoreStyle, pkChar,
     pkGreedyRepChar, pkCharChoice, pkGreedyRepSet, pkAny, pkAnyRune,
     pkNewLine, pkGreedyAny:
    result = 1
  of pkNonTerminal:
    # we cannot inline a rule with a non-terminal
    result = InlineThreshold+1
  else:
    for i in 0..n.len-1:
      inc(result, spaceCost(n.sons[i]))
      if result >= InlineThreshold: break

proc nonterminal*(n: PNonTerminal): TPeg = 
  ## constructs a PEG that consists of the nonterminal symbol
  assert n != nil
  if ntDeclared in n.flags and spaceCost(n.rule) < InlineThreshold:
    when false: echo "inlining symbol: ", n.name
    result = n.rule # inlining of rule enables better optimizations
  else:
    result.kind = pkNonTerminal
    result.nt = n

proc newNonTerminal*(name: string, line, column: int): PNonTerminal =
  ## constructs a nonterminal symbol
  new(result)
  result.name = name
  result.line = line
  result.col = column

template letters*: expr =
  ## expands to ``charset({'A'..'Z', 'a'..'z'})``
  charset({'A'..'Z', 'a'..'z'})
  
template digits*: expr =
  ## expands to ``charset({'0'..'9'})``
  charset({'0'..'9'})

template whitespace*: expr =
  ## expands to ``charset({' ', '\9'..'\13'})``
  charset({' ', '\9'..'\13'})
  
template identChars*: expr =
  ## expands to ``charset({'a'..'z', 'A'..'Z', '0'..'9', '_'})``
  charset({'a'..'z', 'A'..'Z', '0'..'9', '_'})
  
template identStartChars*: expr =
  ## expands to ``charset({'A'..'Z', 'a'..'z', '_'})``
  charset({'a'..'z', 'A'..'Z', '_'})

template ident*: expr =
  ## same as ``[a-zA-Z_][a-zA-z_0-9]*``; standard identifier
  sequence(charset({'a'..'z', 'A'..'Z', '_'}),
           *charset({'a'..'z', 'A'..'Z', '0'..'9', '_'}))
  
template natural*: expr =
  ## same as ``\d+``
  +digits

# ------------------------- debugging -----------------------------------------

proc esc(c: char, reserved = {'\0'..'\255'}): string = 
  case c
  of '\b': result = "\\b"
  of '\t': result = "\\t"
  of '\c': result = "\\c"
  of '\L': result = "\\l"
  of '\v': result = "\\v"
  of '\f': result = "\\f"
  of '\e': result = "\\e"
  of '\a': result = "\\a"
  of '\\': result = "\\\\"
  of 'a'..'z', 'A'..'Z', '0'..'9', '_': result = $c
  elif c < ' ' or c >= '\128': result = '\\' & $ord(c)
  elif c in reserved: result = '\\' & c
  else: result = $c
  
proc singleQuoteEsc(c: Char): string = return "'" & esc(c, {'\''}) & "'"

proc singleQuoteEsc(str: string): string = 
  result = "'"
  for c in items(str): add result, esc(c, {'\''})
  add result, '\''
  
proc charSetEscAux(cc: set[char]): string = 
  const reserved = {'^', '-', ']'}
  result = ""
  var c1 = 0
  while c1 <= 0xff: 
    if chr(c1) in cc: 
      var c2 = c1
      while c2 < 0xff and chr(succ(c2)) in cc: inc(c2)
      if c1 == c2: 
        add result, esc(chr(c1), reserved)
      elif c2 == succ(c1): 
        add result, esc(chr(c1), reserved) & esc(chr(c2), reserved)
      else: 
        add result, esc(chr(c1), reserved) & '-' & esc(chr(c2), reserved)
      c1 = c2
    inc(c1)
  
proc CharSetEsc(cc: set[char]): string =
  if card(cc) >= 128+64: 
    result = "[^" & CharSetEscAux({'\1'..'\xFF'} - cc) & ']'
  else: 
    result = '[' & CharSetEscAux(cc) & ']'
  
proc toStrAux(r: TPeg, res: var string) = 
  case r.kind
  of pkEmpty: add(res, "()")
  of pkAny: add(res, '.')
  of pkAnyRune: add(res, '_')
  of pkNewline: add(res, "\\n")
  of pkTerminal: add(res, singleQuoteEsc(r.term))
  of pkTerminalIgnoreCase:
    add(res, 'i')
    add(res, singleQuoteEsc(r.term))
  of pkTerminalIgnoreStyle:
    add(res, 'y')
    add(res, singleQuoteEsc(r.term))
  of pkChar: add(res, singleQuoteEsc(r.ch))
  of pkCharChoice: add(res, charSetEsc(r.charChoice^))
  of pkNonTerminal: add(res, r.nt.name)
  of pkSequence:
    add(res, '(')
    toStrAux(r.sons[0], res)
    for i in 1 .. high(r.sons):
      add(res, ' ')
      toStrAux(r.sons[i], res)
    add(res, ')')
  of pkOrderedChoice:
    add(res, '(')
    toStrAux(r.sons[0], res)
    for i in 1 .. high(r.sons):
      add(res, " / ")
      toStrAux(r.sons[i], res)
    add(res, ')')
  of pkGreedyRep:
    toStrAux(r.sons[0], res)
    add(res, '*')
  of pkGreedyRepChar:
    add(res, singleQuoteEsc(r.ch))
    add(res, '*')
  of pkGreedyRepSet:
    add(res, charSetEsc(r.charChoice^))
    add(res, '*')
  of pkGreedyAny:
    add(res, ".*")
  of pkOption:
    toStrAux(r.sons[0], res)
    add(res, '?')
  of pkAndPredicate:
    add(res, '&')
    toStrAux(r.sons[0], res)
  of pkNotPredicate:
    add(res, '!')
    toStrAux(r.sons[0], res)
  of pkSearch:
    add(res, '@')
    toStrAux(r.sons[0], res)
  of pkCapture:
    add(res, '{')
    toStrAux(r.sons[0], res)    
    add(res, '}')
  of pkBackRef: 
    add(res, '$')
    add(res, $r.index)
  of pkBackRefIgnoreCase: 
    add(res, "i$")
    add(res, $r.index)
  of pkBackRefIgnoreStyle: 
    add(res, "y$")
    add(res, $r.index)
  of pkRule:
    toStrAux(r.sons[0], res)    
    add(res, " <- ")
    toStrAux(r.sons[1], res)
  of pkList:
    for i in 0 .. high(r.sons):
      toStrAux(r.sons[i], res)
      add(res, "\n")  

proc `$` *(r: TPeg): string =
  ## converts a PEG to its string representation
  result = ""
  toStrAux(r, result)

# --------------------- core engine -------------------------------------------

type
  TMatchClosure {.final.} = object
    matches: array[0..maxSubpatterns-1, tuple[first, last: int]]
    ml: int

when not useUnicode:
  type
    TRune = char
  template fastRuneAt(s, i, ch: expr) =
    ch = s[i]
    inc(i)
  template runeLenAt(s, i: expr): expr = 1

proc m(s: string, p: TPeg, start: int, c: var TMatchClosure): int =
  ## this implements a simple PEG interpreter. Thanks to superoperators it
  ## has competitive performance nevertheless.
  ## Returns -1 if it does not match, else the length of the match
  case p.kind
  of pkEmpty: result = 0 # match of length 0
  of pkAny:
    if s[start] != '\0': result = 1
    else: result = -1
  of pkAnyRune:
    if s[start] != '\0':
      result = runeLenAt(s, start)
    else:
      result = -1
  of pkGreedyAny:
    result = len(s) - start
  of pkNewLine:
    if s[start] == '\L': result = 1
    elif s[start] == '\C':
      if s[start+1] == '\L': result = 2
      else: result = 1
    else: result = -1
  of pkTerminal:
    result = len(p.term)
    for i in 0..result-1:
      if p.term[i] != s[start+i]:
        result = -1
        break
  of pkTerminalIgnoreCase:
    var
      i = 0
      a, b: TRune
    result = start
    while i < len(p.term):
      fastRuneAt(p.term, i, a)
      fastRuneAt(s, result, b)
      if toLower(a) != toLower(b):
        result = -1
        break
    dec(result, start)
  of pkTerminalIgnoreStyle:
    var
      i = 0
      a, b: TRune
    result = start
    while i < len(p.term):
      while true:
        fastRuneAt(p.term, i, a)
        if a != TRune('_'): break
      while true:
        fastRuneAt(s, result, b)
        if b != TRune('_'): break
      if toLower(a) != toLower(b):
        result = -1
        break
    dec(result, start)
  of pkChar:
    if p.ch == s[start]: result = 1
    else: result = -1
  of pkCharChoice:
    if contains(p.charChoice^, s[start]): result = 1
    else: result = -1
  of pkNonTerminal:
    var oldMl = c.ml
    when false: echo "enter: ", p.nt.name
    result = m(s, p.nt.rule, start, c)
    when false: echo "leave: ", p.nt.name
    if result < 0: c.ml = oldMl
  of pkSequence:
    var oldMl = c.ml  
    result = 0
    for i in 0..high(p.sons):
      var x = m(s, p.sons[i], start+result, c)
      if x < 0:
        c.ml = oldMl
        result = -1
        break
      else: inc(result, x)
  of pkOrderedChoice:
    var oldMl = c.ml
    for i in 0..high(p.sons):
      result = m(s, p.sons[i], start, c)
      if result >= 0: break
      c.ml = oldMl
  of pkSearch:
    var oldMl = c.ml
    result = 0
    while start+result < s.len:
      var x = m(s, p.sons[0], start+result, c)
      if x >= 0:
        inc(result, x)
        return
      inc(result)
    result = -1
    c.ml = oldMl
  of pkGreedyRep:
    result = 0
    while true:
      var x = m(s, p.sons[0], start+result, c)
      # if x == 0, we have an endless loop; so the correct behaviour would be
      # not to break. But endless loops can be easily introduced:
      # ``(comment / \w*)*`` is such an example. Breaking for x == 0 does the
      # expected thing in this case.
      if x <= 0: break
      inc(result, x)
  of pkGreedyRepChar:
    result = 0
    var ch = p.ch
    while ch == s[start+result]: inc(result)
  of pkGreedyRepSet:
    result = 0
    while contains(p.charChoice^, s[start+result]): inc(result)
  of pkOption:
    result = max(0, m(s, p.sons[0], start, c))
  of pkAndPredicate:
    var oldMl = c.ml
    result = m(s, p.sons[0], start, c)
    if result >= 0: result = 0 # do not consume anything
    else: c.ml = oldMl
  of pkNotPredicate:
    var oldMl = c.ml
    result = m(s, p.sons[0], start, c)
    if result < 0: result = 0
    else:
      c.ml = oldMl
      result = -1
  of pkCapture:
    var idx = c.ml # reserve a slot for the subpattern
    inc(c.ml)
    result = m(s, p.sons[0], start, c)
    if result >= 0:
      if idx < maxSubpatterns:
        c.matches[idx] = (start, start+result-1)
      #else: silently ignore the capture
    else:
      c.ml = idx
  of pkBackRef: 
    if p.index >= c.ml: return -1
    var (a, b) = c.matches[p.index]
    result = m(s, term(s.copy(a, b)), start, c)
  of pkBackRefIgnoreCase:
    if p.index >= c.ml: return -1
    var (a, b) = c.matches[p.index]
    result = m(s, termIgnoreCase(s.copy(a, b)), start, c)
  of pkBackRefIgnoreStyle:
    if p.index >= c.ml: return -1
    var (a, b) = c.matches[p.index]
    result = m(s, termIgnoreStyle(s.copy(a, b)), start, c)
  of pkRule, pkList: assert false

proc match*(s: string, pattern: TPeg, matches: var openarray[string],
            start = 0): bool =
  ## returns ``true`` if ``s[start..]`` matches the ``pattern`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.
  var c: TMatchClosure
  result = m(s, pattern, start, c) == len(s)
  if result:
    for i in 0..c.ml-1:
      matches[i] = copy(s, c.matches[i][0], c.matches[i][1])

proc match*(s: string, pattern: TPeg, start = 0): bool =
  ## returns ``true`` if ``s`` matches the ``pattern`` beginning from ``start``.
  var c: TMatchClosure
  result = m(s, pattern, start, c) == len(s)

proc matchLen*(s: string, pattern: TPeg, matches: var openarray[string],
               start = 0): int =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen. It's possible that a suffix of `s` remains
  ## that does not belong to the match.
  var c: TMatchClosure
  result = m(s, pattern, start, c)
  if result >= 0:
    for i in 0..c.ml-1:
      matches[i] = copy(s, c.matches[i][0], c.matches[i][1])

proc matchLen*(s: string, pattern: TPeg, start = 0): int =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen. It's possible that a suffix of `s` remains
  ## that does not belong to the match.
  var c: TMatchClosure
  result = m(s, pattern, start, c)

proc find*(s: string, pattern: TPeg, matches: var openarray[string],
           start = 0): int =
  ## returns the starting position of ``pattern`` in ``s`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches`` and -1 is returned.
  for i in 0 .. s.len-1:
    if matchLen(s, pattern, matches, i) >= 0: return i
  return -1
  # could also use the pattern here: (!P .)* P
  
proc find*(s: string, pattern: TPeg, start = 0): int =
  ## returns the starting position of ``pattern`` in ``s``. If it does not
  ## match, -1 is returned.
  for i in 0 .. s.len-1:
    if matchLen(s, pattern, i) >= 0: return i
  return -1
  
template `=~`*(s: string, pattern: TPeg): expr =
  ## This calls ``match`` with an implicit declared ``matches`` array that 
  ## can be used in the scope of the ``=~`` call: 
  ## 
  ## .. code-block:: nimrod
  ##
  ##   if line =~ peg"\s* {\w+} \s* '=' \s* {\w+}": 
  ##     # matches a key=value pair:
  ##     echo("Key: ", matches[0])
  ##     echo("Value: ", matches[1])
  ##   elif line =~ peg"\s*{'#'.*}":
  ##     # matches a comment
  ##     # note that the implicit ``matches`` array is different from the
  ##     # ``matches`` array of the first branch
  ##     echo("comment: ", matches[0])
  ##   else:
  ##     echo("syntax error")
  ##  
  when not definedInScope(matches):
    var matches: array[0..maxSubpatterns-1, string]
  match(s, pattern, matches)

# ------------------------- more string handling ------------------------------

proc contains*(s: string, pattern: TPeg, start = 0): bool =
  ## same as ``find(s, pattern, start) >= 0``
  return find(s, pattern, start) >= 0

proc contains*(s: string, pattern: TPeg, matches: var openArray[string],
              start = 0): bool =
  ## same as ``find(s, pattern, matches, start) >= 0``
  return find(s, pattern, matches, start) >= 0

proc startsWith*(s: string, prefix: TPeg): bool =
  ## returns true if `s` starts with the pattern `prefix`
  result = matchLen(s, prefix) >= 0

proc endsWith*(s: string, suffix: TPeg): bool =
  ## returns true if `s` ends with the pattern `prefix`
  for i in 0 .. s.len-1:
    if matchLen(s, suffix, i) == s.len - i: return true

proc replace*(s: string, sub: TPeg, by: string): string =
  ## Replaces `sub` in `s` by the string `by`. Captures can be accessed in `by`
  ## with the notation ``$i`` and ``$#`` (see strutils.`%`). Examples:
  ##
  ## .. code-block:: nimrod
  ##   "var1=key; var2=key2".replace(peg"{\ident}'='{\ident}", "$1<-$2$2")
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##
  ##   "var1<-keykey; val2<-key2key2"
  result = ""
  var i = 0
  var caps: array[0..maxSubpatterns-1, string]
  while i < s.len:
    var x = matchLen(s, sub, caps, i)
    if x <= 0:
      add(result, s[i])
      inc(i)
    else:
      addf(result, by, caps)
      inc(i, x)
  # copy the rest:
  add(result, copy(s, i))
  
proc parallelReplace*(s: string, subs: openArray[
                      tuple[pattern: TPeg, repl: string]]): string = 
  ## Returns a modified copy of `s` with the substitutions in `subs`
  ## applied in parallel.
  result = ""
  var i = 0
  var caps: array[0..maxSubpatterns-1, string]
  while i < s.len:
    block searchSubs:
      for j in 0..high(subs):
        var x = matchLen(s, subs[j][0], caps, i)
        if x > 0:
          addf(result, subs[j][1], caps)
          inc(i, x)
          break searchSubs
      add(result, s[i])
      inc(i)
  # copy the rest:
  add(result, copy(s, i))  
  
proc transformFile*(infile, outfile: string,
                    subs: openArray[tuple[pattern: TPeg, repl: string]]) =
  ## reads in the file `infile`, performs a parallel replacement (calls
  ## `parallelReplace`) and writes back to `outfile`. Calls ``quit`` if an
  ## error occurs. This is supposed to be used for quick scripting.
  var x = readFile(infile)
  if not isNil(x):
    var f: TFile
    if open(f, outfile, fmWrite):
      write(f, x.parallelReplace(subs))
      close(f)
    else:
      quit("cannot open for writing: " & outfile)
  else:
    quit("cannot open for reading: " & infile)
  
iterator split*(s: string, sep: TPeg): string =
  ## Splits the string `s` into substrings.
  ##
  ## Substrings are separated by the PEG `sep`.
  ## Examples:
  ##
  ## .. code-block:: nimrod
  ##   for word in split("00232this02939is39an22example111", peg"\d+"):
  ##     writeln(stdout, word)
  ##
  ## Results in:
  ##
  ## .. code-block:: nimrod
  ##   "this"
  ##   "is"
  ##   "an"
  ##   "example"
  ##
  var
    first = 0
    last = 0
  while last < len(s):
    var x = matchLen(s, sep, last)
    if x > 0: inc(last, x)
    first = last
    while last < len(s):
      inc(last)
      x = matchLen(s, sep, last)
      if x > 0: break
    if first < last:
      yield copy(s, first, last-1)

proc split*(s: string, sep: TPeg): seq[string] {.noSideEffect.} =
  ## Splits the string `s` into substrings.
  accumulateResult(split(s, sep))

# ------------------- scanner -------------------------------------------------

type
  TModifier = enum
    modNone,
    modVerbatim,
    modIgnoreCase,
    modIgnoreStyle
  TTokKind = enum       ## enumeration of all tokens
    tkInvalid,          ## invalid token
    tkEof,              ## end of file reached
    tkAny,              ## .
    tkAnyRune,          ## _
    tkIdentifier,       ## abc
    tkStringLit,        ## "abc" or 'abc'
    tkCharSet,          ## [^A-Z]
    tkParLe,            ## '('
    tkParRi,            ## ')'
    tkCurlyLe,          ## '{'
    tkCurlyRi,          ## '}'
    tkArrow,            ## '<-'
    tkBar,              ## '/'
    tkStar,             ## '*'
    tkPlus,             ## '+'
    tkAmp,              ## '&'
    tkNot,              ## '!'
    tkOption,           ## '?'
    tkAt,               ## '@'
    tkBuiltin,          ## \identifier
    tkEscaped,          ## \\
    tkDollar            ## '$'
  
  TToken {.final.} = object  ## a token
    kind: TTokKind           ## the type of the token
    modifier: TModifier
    literal: string          ## the parsed (string) literal
    charset: set[char]       ## if kind == tkCharSet
    index: int               ## if kind == tkDollar
  
  TPegLexer = object          ## the lexer object.
    bufpos: int               ## the current position within the buffer
    buf: cstring              ## the buffer itself
    LineNumber: int           ## the current line number
    lineStart: int            ## index of last line start in buffer
    colOffset: int            ## column to add
    filename: string

const
  tokKindToStr: array[TTokKind, string] = [
    "invalid", "[EOF]", ".", "_", "identifier", "string literal",
    "character set", "(", ")", "{", "}", "<-", "/", "*", "+", "&", "!", "?",
    "@", "built-in", "escaped", "$"
  ]

proc HandleCR(L: var TPegLexer, pos: int): int =
  assert(L.buf[pos] == '\c')
  inc(L.linenumber)
  result = pos+1
  if L.buf[result] == '\L': inc(result)
  L.lineStart = result

proc HandleLF(L: var TPegLexer, pos: int): int =
  assert(L.buf[pos] == '\L')
  inc(L.linenumber)
  result = pos+1
  L.lineStart = result

proc init(L: var TPegLexer, input, filename: string, line = 1, col = 0) = 
  L.buf = input
  L.bufpos = 0
  L.lineNumber = line
  L.colOffset = col
  L.lineStart = 0
  L.filename = filename

proc getColumn(L: TPegLexer): int {.inline.} = 
  result = abs(L.bufpos - L.lineStart) + L.colOffset

proc getLine(L: TPegLexer): int {.inline.} = 
  result = L.linenumber
  
proc errorStr(L: TPegLexer, msg: string, line = -1, col = -1): string =
  var line = if line < 0: getLine(L) else: line
  var col = if col < 0: getColumn(L) else: col
  result = "$1($2, $3) Error: $4" % [L.filename, $line, $col, msg]

proc handleHexChar(c: var TPegLexer, xi: var int) = 
  case c.buf[c.bufpos]
  of '0'..'9': 
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)
  of 'a'..'f': 
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('a') + 10)
    inc(c.bufpos)
  of 'A'..'F': 
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('A') + 10)
    inc(c.bufpos)
  else: nil

proc getEscapedChar(c: var TPegLexer, tok: var TToken) = 
  inc(c.bufpos)
  case c.buf[c.bufpos]
  of 'r', 'R', 'c', 'C': 
    add(tok.literal, '\c')
    Inc(c.bufpos)
  of 'l', 'L': 
    add(tok.literal, '\L')
    Inc(c.bufpos)
  of 'f', 'F': 
    add(tok.literal, '\f')
    inc(c.bufpos)
  of 'e', 'E': 
    add(tok.literal, '\e')
    Inc(c.bufpos)
  of 'a', 'A': 
    add(tok.literal, '\a')
    Inc(c.bufpos)
  of 'b', 'B': 
    add(tok.literal, '\b')
    Inc(c.bufpos)
  of 'v', 'V': 
    add(tok.literal, '\v')
    Inc(c.bufpos)
  of 't', 'T': 
    add(tok.literal, '\t')
    Inc(c.bufpos)
  of 'x', 'X': 
    inc(c.bufpos)
    var xi = 0
    handleHexChar(c, xi)
    handleHexChar(c, xi)
    if xi == 0: tok.kind = tkInvalid
    else: add(tok.literal, Chr(xi))
  of '0'..'9': 
    var val = ord(c.buf[c.bufpos]) - ord('0')
    Inc(c.bufpos)
    var i = 1
    while (i <= 3) and (c.buf[c.bufpos] in {'0'..'9'}): 
      val = val * 10 + ord(c.buf[c.bufpos]) - ord('0')
      inc(c.bufpos)
      inc(i)
    if val > 0 and val <= 255: add(tok.literal, chr(val))
    else: tok.kind = tkInvalid
  of '\0'..'\31':
    tok.kind = tkInvalid
  elif c.buf[c.bufpos] in strutils.letters:
    tok.kind = tkInvalid
  else:
    add(tok.literal, c.buf[c.bufpos])
    Inc(c.bufpos)
  
proc skip(c: var TPegLexer) = 
  var pos = c.bufpos
  var buf = c.buf
  while true: 
    case buf[pos]
    of ' ', '\t': 
      Inc(pos)
    of '#':
      while not (buf[pos] in {'\c', '\L', '\0'}): inc(pos)
    of '\c':
      pos = HandleCR(c, pos)
      buf = c.buf
    of '\L': 
      pos = HandleLF(c, pos)
      buf = c.buf
    else: 
      break                   # EndOfFile also leaves the loop
  c.bufpos = pos
  
proc getString(c: var TPegLexer, tok: var TToken) = 
  tok.kind = tkStringLit
  var pos = c.bufPos + 1
  var buf = c.buf
  var quote = buf[pos-1]
  while true: 
    case buf[pos]
    of '\\':
      c.bufpos = pos
      getEscapedChar(c, tok)
      pos = c.bufpos
    of '\c', '\L', '\0':
      tok.kind = tkInvalid
      break
    elif buf[pos] == quote:
      inc(pos)
      break      
    else:
      add(tok.literal, buf[pos])
      Inc(pos)
  c.bufpos = pos
  
proc getDollar(c: var TPegLexer, tok: var TToken) = 
  var pos = c.bufPos + 1
  var buf = c.buf
  if buf[pos] in {'0'..'9'}:
    tok.kind = tkDollar
    tok.index = 0
    while buf[pos] in {'0'..'9'}:
      tok.index = tok.index * 10 + ord(buf[pos]) - ord('0')
      inc(pos)
  else:
    tok.kind = tkInvalid
  c.bufpos = pos
  
proc getCharSet(c: var TPegLexer, tok: var TToken) = 
  tok.kind = tkCharSet
  tok.charset = {}
  var pos = c.bufPos + 1
  var buf = c.buf
  var caret = false
  if buf[pos] == '^':
    inc(pos)
    caret = true
  while true:
    var ch: char
    case buf[pos]
    of ']':
      inc(pos)
      break
    of '\\':
      c.bufpos = pos
      getEscapedChar(c, tok)
      pos = c.bufpos
      ch = tok.literal[tok.literal.len-1]
    of '\C', '\L', '\0':
      tok.kind = tkInvalid
      break
    else: 
      ch = buf[pos]
      Inc(pos)
    incl(tok.charset, ch)
    if buf[pos] == '-':
      if buf[pos+1] == ']':
        incl(tok.charset, '-')
        inc(pos)
      else:
        inc(pos)
        var ch2: char
        case buf[pos]
        of '\\':
          c.bufpos = pos
          getEscapedChar(c, tok)
          pos = c.bufpos
          ch2 = tok.literal[tok.literal.len-1]
        of '\C', '\L', '\0':
          tok.kind = tkInvalid
          break
        else: 
          ch2 = buf[pos]
          Inc(pos)
        for i in ord(ch)+1 .. ord(ch2):
          incl(tok.charset, chr(i))
  c.bufpos = pos
  if caret: tok.charset = {'\1'..'\xFF'} - tok.charset
  
proc getSymbol(c: var TPegLexer, tok: var TToken) = 
  var pos = c.bufpos
  var buf = c.buf
  while true: 
    add(tok.literal, buf[pos])
    Inc(pos)
    if buf[pos] notin strutils.IdentChars: break
  c.bufpos = pos
  tok.kind = tkIdentifier

proc getBuiltin(c: var TPegLexer, tok: var TToken) =
  if c.buf[c.bufpos+1] in strutils.Letters:
    inc(c.bufpos)
    getSymbol(c, tok)
    tok.kind = tkBuiltin
  else:
    tok.kind = tkEscaped
    getEscapedChar(c, tok) # may set tok.kind to tkInvalid

proc getTok(c: var TPegLexer, tok: var TToken) = 
  tok.kind = tkInvalid
  tok.modifier = modNone
  setlen(tok.literal, 0)
  skip(c)
  case c.buf[c.bufpos]
  of '{':
    tok.kind = tkCurlyLe
    inc(c.bufpos)
    add(tok.literal, '{')
  of '}': 
    tok.kind = tkCurlyRi
    inc(c.bufpos)
    add(tok.literal, '}')
  of '[': 
    getCharset(c, tok)
  of '(':
    tok.kind = tkParLe
    Inc(c.bufpos)
    add(tok.literal, '(')
  of ')':
    tok.kind = tkParRi
    Inc(c.bufpos)
    add(tok.literal, ')')
  of '.': 
    tok.kind = tkAny
    inc(c.bufpos)
    add(tok.literal, '.')
  of '_':
    tok.kind = tkAnyRune
    inc(c.bufpos)
    add(tok.literal, '_')
  of '\\': 
    getBuiltin(c, tok)
  of '\'', '"': getString(c, tok)
  of '$': getDollar(c, tok)
  of '\0': 
    tok.kind = tkEof
    tok.literal = "[EOF]"
  of 'a'..'z', 'A'..'Z', '\128'..'\255':
    getSymbol(c, tok)
    if c.buf[c.bufpos] in {'\'', '"', '$'}:
      case tok.literal
      of "i": tok.modifier = modIgnoreCase
      of "y": tok.modifier = modIgnoreStyle
      of "v": tok.modifier = modVerbatim
      else: nil
      setLen(tok.literal, 0)
      if c.buf[c.bufpos] == '$':
        getDollar(c, tok)
      else:
        getString(c, tok)
      if tok.modifier == modNone: tok.kind = tkInvalid
  of '+':
    tok.kind = tkPlus
    inc(c.bufpos)
    add(tok.literal, '+')
  of '*':
    tok.kind = tkStar
    inc(c.bufpos)
    add(tok.literal, '+')
  of '<':
    if c.buf[c.bufpos+1] == '-':
      inc(c.bufpos, 2)
      tok.kind = tkArrow
      add(tok.literal, "<-")
    else:
      add(tok.literal, '<')
  of '/':
    tok.kind = tkBar
    inc(c.bufpos)
    add(tok.literal, '/')
  of '?':
    tok.kind = tkOption
    inc(c.bufpos)
    add(tok.literal, '?')
  of '!':
    tok.kind = tkNot
    inc(c.bufpos)
    add(tok.literal, '!')
  of '&':
    tok.kind = tkAmp
    inc(c.bufpos)
    add(tok.literal, '!')
  of '@':
    tok.kind = tkAt
    inc(c.bufpos)
    add(tok.literal, '@')
  else:
    add(tok.literal, c.buf[c.bufpos])
    inc(c.bufpos)

proc arrowIsNextTok(c: TPegLexer): bool =
  # the only look ahead we need
  var pos = c.bufpos
  while c.buf[pos] in {'\t', ' '}: inc(pos)
  result = c.buf[pos] == '<' and c.buf[pos+1] == '-'

# ----------------------------- parser ----------------------------------------
    
type
  EInvalidPeg* = object of EBase ## raised if an invalid PEG has been detected
  TPegParser = object of TPegLexer ## the PEG parser object
    tok: TToken
    nonterms: seq[PNonTerminal]
    modifier: TModifier
    captures: int

proc pegError(p: TPegParser, msg: string, line = -1, col = -1) =
  var e: ref EInvalidPeg
  new(e)
  e.msg = errorStr(p, msg, line, col)
  raise e

proc getTok(p: var TPegParser) = 
  getTok(p, p.tok)
  if p.tok.kind == tkInvalid: pegError(p, "invalid token")

proc eat(p: var TPegParser, kind: TTokKind) =
  if p.tok.kind == kind: getTok(p)
  else: pegError(p, tokKindToStr[kind] & " expected")

proc parseExpr(p: var TPegParser): TPeg

proc getNonTerminal(p: TPegParser, name: string): PNonTerminal =
  for i in 0..high(p.nonterms):
    result = p.nonterms[i]
    if cmpIgnoreStyle(result.name, name) == 0: return
  # forward reference:
  result = newNonTerminal(name, getLine(p), getColumn(p))
  add(p.nonterms, result)

proc modifiedTerm(s: string, m: TModifier): TPeg =
  case m
  of modNone, modVerbatim: result = term(s)
  of modIgnoreCase: result = termIgnoreCase(s)
  of modIgnoreStyle: result = termIgnoreStyle(s)

proc modifiedBackref(s: int, m: TModifier): TPeg =
  case m
  of modNone, modVerbatim: result = backRef(s)
  of modIgnoreCase: result = backRefIgnoreCase(s)
  of modIgnoreStyle: result = backRefIgnoreStyle(s)

proc primary(p: var TPegParser): TPeg =
  case p.tok.kind
  of tkAmp:
    getTok(p)
    return &primary(p)
  of tkNot:
    getTok(p)
    return !primary(p)
  of tkAt:
    getTok(p)
    return @primary(p)
  else: nil
  case p.tok.kind
  of tkIdentifier:
    if not arrowIsNextTok(p):
      var nt = getNonTerminal(p, p.tok.literal)
      incl(nt.flags, ntUsed)
      result = nonTerminal(nt)
      getTok(p)
    else:
      pegError(p, "expression expected, but found: " & p.tok.literal)
  of tkStringLit:
    var m = p.tok.modifier
    if m == modNone: m = p.modifier
    result = modifiedTerm(p.tok.literal, m)
    getTok(p)
  of tkCharSet:
    if '\0' in p.tok.charset:
      pegError(p, "binary zero ('\\0') not allowed in character class")
    result = charset(p.tok.charset)
    getTok(p)
  of tkParLe:
    getTok(p)
    result = parseExpr(p)
    eat(p, tkParRi)
  of tkCurlyLe:
    getTok(p)
    result = capture(parseExpr(p))
    eat(p, tkCurlyRi)
    inc(p.captures)
  of tkAny:
    result = any()
    getTok(p)
  of tkAnyRune:
    result = anyRune()
    getTok(p)
  of tkBuiltin:
    case p.tok.literal
    of "n": result = newLine()
    of "d": result = charset({'0'..'9'})
    of "D": result = charset({'\1'..'\xff'} - {'0'..'9'})
    of "s": result = charset({' ', '\9'..'\13'})
    of "S": result = charset({'\1'..'\xff'} - {' ', '\9'..'\13'})
    of "w": result = charset({'a'..'z', 'A'..'Z', '_'})
    of "W": result = charset({'\1'..'\xff'} - {'a'..'z', 'A'..'Z', '_'})
    of "ident": result = pegs.ident
    else: pegError(p, "unknown built-in: " & p.tok.literal)
    getTok(p)
  of tkEscaped:
    result = term(p.tok.literal[0])
    getTok(p)
  of tkDollar:
    var m = p.tok.modifier
    if m == modNone: m = p.modifier
    result = modifiedBackRef(p.tok.index, m)
    if p.tok.index < 0 or p.tok.index > p.captures: 
      pegError(p, "invalid back reference index: " & $p.tok.index)
    getTok(p)
  else:
    pegError(p, "expression expected, but found: " & p.tok.literal)
    getTok(p) # we must consume a token here to prevent endless loops!
  while true:
    case p.tok.kind
    of tkOption:
      result = ?result
      getTok(p)
    of tkStar:
      result = *result
      getTok(p)
    of tkPlus:
      result = +result
      getTok(p)
    else: break

proc seqExpr(p: var TPegParser): TPeg =
  result = primary(p)
  while true:
    case p.tok.kind
    of tkAmp, tkNot, tkAt, tkStringLit, tkCharset, tkParLe, tkCurlyLe,
       tkAny, tkAnyRune, tkBuiltin, tkEscaped, tkDollar:
      result = sequence(result, primary(p))
    of tkIdentifier:
      if not arrowIsNextTok(p):
        result = sequence(result, primary(p))
      else: break
    else: break

proc parseExpr(p: var TPegParser): TPeg =
  result = seqExpr(p)
  while p.tok.kind == tkBar:
    getTok(p)
    result = result / seqExpr(p)
  
proc parseRule(p: var TPegParser): PNonTerminal =
  if p.tok.kind == tkIdentifier and arrowIsNextTok(p):
    result = getNonTerminal(p, p.tok.literal)
    if ntDeclared in result.flags:
      pegError(p, "attempt to redefine: " & result.name)
    result.line = getLine(p)
    result.col = getColumn(p)
    getTok(p)
    eat(p, tkArrow)
    result.rule = parseExpr(p)
    incl(result.flags, ntDeclared) # NOW inlining may be attempted
  else:
    pegError(p, "rule expected, but found: " & p.tok.literal)
  
proc rawParse(p: var TPegParser): TPeg =
  ## parses a rule or a PEG expression
  if p.tok.kind == tkBuiltin:
    case p.tok.literal
    of "i":
      p.modifier = modIgnoreCase
      getTok(p)
    of "y":
      p.modifier = modIgnoreStyle
      getTok(p)
    else: nil
  if p.tok.kind == tkIdentifier and arrowIsNextTok(p):
    result = parseRule(p).rule
    while p.tok.kind != tkEof:
      discard parseRule(p)
  else:
    result = parseExpr(p)
  if p.tok.kind != tkEof:
    pegError(p, "EOF expected, but found: " & p.tok.literal)
  for i in 0..high(p.nonterms):
    var nt = p.nonterms[i]
    if ntDeclared notin nt.flags:
      pegError(p, "undeclared identifier: " & nt.name, nt.line, nt.col)
    elif ntUsed notin nt.flags and i > 0:
      pegError(p, "unused rule: " & nt.name, nt.line, nt.col)

proc parsePeg*(input: string, filename = "pattern", line = 1, col = 0): TPeg =
  var p: TPegParser
  init(TPegLexer(p), input, filename, line, col)
  p.tok.kind = tkInvalid
  p.tok.modifier = modNone
  p.tok.literal = ""
  p.tok.charset = {}
  p.nonterms = @[]
  getTok(p)
  result = rawParse(p)

proc peg*(pattern: string): TPeg =
  ## constructs a TPeg object from the `pattern`. The short name has been
  ## chosen to encourage its use as a raw string modifier::
  ##
  ##   peg"{\ident} \s* '=' \s* {.*}"
  result = parsePeg(pattern, "pattern")

when isMainModule:
  assert match("(a b c)", peg"'(' @ ')'")
  assert match("W_HI_Le", peg"\y 'while'")
  assert(not match("W_HI_L", peg"\y 'while'"))
  assert(not match("W_HI_Le", peg"\y v'while'"))
  assert match("W_HI_Le", peg"y'while'")
  
  assert($ +digits == $peg"\d+")
  assert "0158787".match(peg"\d+")
  assert "ABC 0232".match(peg"\w+\s+\d+")
  assert "ABC".match(peg"\d+ / \w+")

  for word in split("00232this02939is39an22example111", peg"\d+"):
    writeln(stdout, word)

  assert matchLen("key", ident) == 3

  var pattern = sequence(ident, *whitespace, term('='), *whitespace, ident)
  assert matchLen("key1=  cal9", pattern) == 11
  
  var ws = newNonTerminal("ws", 1, 1)
  ws.rule = *whitespace
  
  var expr = newNonTerminal("expr", 1, 1)
  expr.rule = sequence(capture(ident), *sequence(
                nonterminal(ws), term('+'), nonterminal(ws), nonterminal(expr)))
  
  var c: TMatchClosure
  var s = "a+b +  c +d+e+f"
  assert m(s, expr.rule, 0, c) == len(s)
  var a = ""
  for i in 0..c.ml-1:
    a.add(copy(s, c.matches[i][0], c.matches[i][1]))
  assert a == "abcdef"
  #echo expr.rule

  #const filename = "lib/devel/peg/grammar.txt"
  #var grammar = parsePeg(newFileStream(filename, fmRead), filename)
  #echo "a <- [abc]*?".match(grammar)
  assert find("_____abc_______", term("abc")) == 5
  assert match("_______ana", peg"A <- 'ana' / . A")
  assert match("abcs%%%", peg"A <- ..A / .A / '%'")

  if "abc" =~ peg"{'a'}'bc' 'xyz' / {\ident}":
    assert matches[0] == "abc"
  else:
    assert false
  
  var g2 = peg"""S <- A B / C D
                 A <- 'a'+
                 B <- 'b'+
                 C <- 'c'+
                 D <- 'd'+
              """
  assert($g2 == "((A B) / (C D))")
  assert match("cccccdddddd", g2)
  assert("var1=key; var2=key2".replace(peg"{\ident}'='{\ident}", "$1<-$2$2") ==
         "var1<-keykey; var2<-key2key2")
  assert "var1=key; var2=key2".endsWith(peg"{\ident}'='{\ident}")

  if "aaaaaa" =~ peg"'aa' !. / ({'a'})+":
    assert matches[0] == "a"
  else:
    assert false
