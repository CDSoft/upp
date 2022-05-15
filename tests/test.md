# UPP test suite

@@( local x = 1
    local y = 2
    z = x + y
)

- foo defined on the command line: foo = @(foo)
- foofoo defined in test_lib.lua: foofoo = @(foofoo)
- z defined in an embedded chunk: z = @(z)
- undefined is not defined: undefined = @(undefined)

foofoo can be undefined: @@(foofoo = nil)foofoo = @(foofoo)
and redefined by reloading test_lib.lua: @@(require "test_lib")foofoo = @(foofoo)

@(include "tests/test_include.md")

# `@` vs `$` notation

:(function notation_1()
    return "`:` works"
end)

@@(function notation_2()
    return "`@` works"
end)

- $(notation_1())$(--[[ fake comment to close the fake LaTeX environment ]] "")
- @(notation_2())

# Some maths

1 + 1 = @(1 + 1)
cos(π) = @(math.cos(math.pi))

# Conditionals

@@(lang = "fr")

lang = @(lang)

@(when(lang=="fr") [[
lang = @(lang) => Ce texte en français doit apparaitre !
]])

@(when(lang=="en") [[
lang = @(lang) => You should not see this text in english!
]])

input files: @(input_files())

output file: @(output_file())

# Blocks (array items)

@@(t = map(function(i) return ("block #%d"):format(i) end, {1, 2, 3}))

## Default separator

@(t)

## Globally overloaded separator

@@(BLOCK_SEP = " - ")
@(t)
@@(BLOCK_SEP = nil)

## Table specific separator

@@(t.sep = "; ")

@(t)

# User defined `__tostring` metamethod

@@(function T(x)
    local t = {val=x}
    local mt = {__tostring = function(t) return ("T(val=%s)"):format(t.val) end}
    return setmetatable(t, mt)
end)

@(T(42))

@@(t = map(T, {1, 2, 3}))

@(t)

# Additional outputs

@@(emit "@(build)/other_file.md" [[
This is another generated file.
It should be in `@(build)`.

z is still @(z).
]])

@@(emit "-complement.txt" [[
This file uses the name of the parent file as prefix.
]])

# Targets

@@( sh [[
    echo "non discoverable target" > @(build)/non_discoverable_target.txt
]] )

# Standard library tests

@@(require "pretty")
@@(BLOCK_SEP = ", ")

## range:

1,2..10: @(range(1, 10))
1,3..9 : @(range(1, 10, 2))
10..1  : @(range(10, 1))
10,8..2: @(range(10, 1, -2))

## map

squares: @(map(function(x) return x*x end, range(1, 10)))
cubes  : @(map(function(x, i) return x*x*x, i end, range(1, 10)) -- only the first returned value shall be used)

## filter

evens: @(filter(function(x) return x % 2 == 0 end, range(1, 10)))

## concat

{1,2,3} + {4,5,6} = @(concat({1,2,3},{4,5,6}))

## merge

{a=1,b=2,c=3} + {d=4,a=5,e=6} = @(pretty(merge({a=1,b=2,c=3},{d=4,a=5,e=6})))

## path

basename a/b/c = @(basename "a/b/c")
dirname  a/b/c = @(dirname "a/b/c")

join a/b c/d e/f = @(join("a/b", "c/d", "e/f"))
join a/b /c/d e/f = @(join("a/b", "/c/d", "e/f"))
join a/b c/d /e/f = @(join("a/b", "c/d", "/e/f"))

## prefix/suffix

add "/" to all items: @(map(prefix"/", {"a", "b", "c"}))
add "/" to all items: @(map(suffix"/", {"a", "b", "c"}))

## Counters

@@(require "counter")

Count A's        : @(count "A") @(count "A") @(count "A")
Count B's from 42: @(count("B", 42)) @(count "B") @(count "B")
More A's         : @(count "A") @(count "A") @(count "A")
More B's         : @(count "B") @(count "B") @(count "B")

## Verbatim sections

@@(foo = "bar")

upp interpolation enabled      : foo = @(foo)
?(false)
upp interpolation disabled     : foo = @(foo)
?(true)
upp interpolation enabled again: foo = @(foo)

