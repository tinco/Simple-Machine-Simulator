         load   R1, Text    ;the start of the string
         load   R2, 1       ;inscrease step
         load   R0,0        ;string
NextChar:load   RF,[R1]     ;get character and print it on screen
         addi   R1,R1,R2    ;increase address
         jmpEQ  RF=R0,Ready ;when string-terminator, then ready
         jmp    NextChar    ;next character
Ready:   halt

Text:    db     10
         db     "Hello world !!",10
         db     "   from the",10
         db     " Simple Simulator",10
         db     0
