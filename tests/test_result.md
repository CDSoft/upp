# UPP test suite



- foo defined on the command line: foo = bar
- foofoo defined in test_lib.lua: foofoo = barbar
- z defined in an embedded chunk: z = 3
- undefined is not defined: undefined = nil

foofoo can be undefined: foofoo = nil
and redefined by reloading test_lib.lua: foofoo = barbar

# Included file

The included file is preprocessed in the same environment.
foo = bar


# Some maths

1 + 1 = 2
cos(π) = -1.0

# Conditionals



lang = fr

lang = fr => Ce texte en français doit apparaitre !




input files: tests/test.md, tests/test2.md

output file: .build/test.md

# Blocks (array items)



## Default separator

block #1
block #2
block #3

## Globally overloaded separator


block #1 - block #2 - block #3


## Table specific separator



block #1; block #2; block #3

# User defined `__tostring` metamethod



T(val=42)



T(val=1)
T(val=2)
T(val=3)

# Additional outputs





# Targets



# Standard library tests




## range:

1,2..10: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
1,3..9 : 1, 3, 5, 7, 9
10..1  : 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
10,8..2: 10, 8, 6, 4, 2

## map

squares: 1, 4, 9, 16, 25, 36, 49, 64, 81, 100

## filter

evens: 2, 4, 6, 8, 10

## concat

{1,2,3} + {4,5,6} = 1, 2, 3, 4, 5, 6

## merge

{a=1,b=2,c=3} + {d=4,a=5,e=6} = {
  a = 5
  b = 2
  c = 3
  d = 4
  e = 6
}

## path

basename a/b/c = c
dirname  a/b/c = a/b

join a/b c/d e/f = a/b/c/d/e/f
join a/b /c/d e/f = /c/d/e/f
join a/b c/d /e/f = /e/f

## prefix/postfix

add "/" to all items: /a, /b, /c
add "/" to all items: a/, b/, c/

## Counters



Count A's        : 1 2 3
Count B's from 42: 42 43 44
More A's         : 4 5 6
More B's         : 45 46 47
# Additional tests

A second file just to make sure `input_files` can contain more than one filename.
