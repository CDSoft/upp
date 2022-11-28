## Implementation

@@(REQTARGET = "code.html")

@(req "R_CODE_A: title of CODE A" {
    refs = "R_SPEC_1 R_SPEC_2",
})

@(req "R_CODE_B: title of CODE B" {
    refs = "R_SPEC_2 R_SPEC_3",
})

### Coverage matrix

@(req.matrix())
