# UPP test suite



- foo defined on the command line: foo = bar
- foofoo defined in test_lib.lua: foofoo = barbar
- z defined in an embedded chunk: z = 3
- undefined is not defined: undefined = $(undefined)

foofoo can be undefined: foofoo = $(foofoo)
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



