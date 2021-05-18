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
