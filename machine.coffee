PROGRAM_START = 0x00 # The memory address of the first instruction
STATEMENT_SIZE = 2 # Two bytes per statement
REGISTERS = 16
MEMORY_WIDTH = 16
MEMORY_HEIGHT = 16
class SimpleMachine
	constructor: () ->
		# Initialize the registers and the memory with 0's
		@registers = (0 for num in [1..REGISTERS])
		# The memory is a 16x16 array
		@memory = ((0 for num in [1..MEMORY_WIDTH]) for x in [1..MEMORY_HEIGHT])
		#program starts at 00
		@program_counter = PROGRAM_START
		@instruction_register = [0,0,0,0]
		@halted = true

	run: () ->
		@halted = false
		while not @halted
			@step()

	step: () ->
		# Split address into array coordinates
		[c_1, c_2] = @split_byte(@program_counter)
		# Split cells into instruction register fields (which are 4-bits)
		@instruction_register = @split_byte(@memory[c_1][c_2]).concat(@split_byte(@memory[c_1][c_2 + 1]))
		# Execute function of instruction
		@instructions[@instruction_register[0]].function.apply(this, @instruction_register[1..3])
		@halted = @instruction_register[0] == 0xC #HALT
		@increase_program_counter()

	increase_program_counter: () ->
		@program_counter += STATEMENT_SIZE

	# Reads an assembly as an array of bytes into memory from offset PROGRAM_START
	load: (assembly) ->
		for byte, i in assembly
			[i_1, i_2] = @split_byte(i)
			@memory[i_1 + PROGRAM_START][i_2] = byte

	##
	#  We have the implementations of the actions in seperate methods so we can hook them for step through representations
	##
	read_register: (r) -> @registers[r]
	read_memory: (x, y) -> @memory[x][y]
	store_register: (r, value) ->
		@registers[r] = value
#		if r == 0xF
#			console.log(String.fromCharCode(value))
	store_memory: (x, y, value) -> @memory[x][y] = value
	join_nibbles: (x, y) -> x << 4 | y
	split_byte: (v) -> [v >> 4, v & 0xF]
	add_integers: (x,y) -> x + y
	add_floats: (x,y) -> 0 # figure out
	or_values: (x,y) -> x | y
	and_values: (x,y) -> x & y
	xor_values: (x,y) -> x ^ y
	rot_value: (v,x) -> v >> 1 | (v & 1 << 7)
	jump: (x) -> @program_counter = x - STATEMENT_SIZE # will be executed next step
	halt: () -> #do nothing

	instructions:
		1:
			description: "LOAD register R with contents of memorycell XY"
			operand: "RXY"
			function: (r,x,y) ->
				@store_register(r, @read_memory(x,y))
		2:
			description: "LOAD register R with value XY"
			operand: "RXY"
			function: (r,x,y) -> @store_register(r, @join_nibbles(x,y))
		3:
			description: "STORE contents of register R in memorycell XY"
			operand: "RXY"
			function: (r,x,y) -> @store_memory(x, y, @read_register(r))
		4:
			description: "MOVE contents of register R into register S"
			operand: "0RS"
			function: (n,r,s) -> @store_register(s, @read_register(r))
		5:
			description: "ADD the contents of registers S and T as if they were in two's complement and store the result in register R"
			operand: "RST"
			function: (r,s,t) -> @store_register(r, @add_integers(@read_register(s), @read_register(t)))
		6:
			description: "ADD the contents of registers S and T as if they were floating point numbers and store the result in register R"
			operand: "RST"
			function: (r,s,t) -> @store_register(r, @add_floats(@read_register(s), @read_register(t)))
		7:
			description: "OR the contents of registers S and T and @store the result in register R"
			operand: "RST"
			function: (r,s,t) -> @store_register(r, @or_values(@read_register(s), @read_register(t)))
		8:
			description: "AND the contents of registers S and T and @store the result in register R"
			operand: "RST"
			function: (r,s,t) -> @store_register(r, @and_values(@read_register(s), @read_register(t)))
		9:
			description: "XOR the contents of registers S and T and @store the result in register R"
			operand: "RST"
			function: (r,s,t) -> @store_register(r, @xor_values(@read_register(s), @read_register(t)))
		0xA:
			description: "ROTATE the contents of register R one bit to the right X times, moving the last bit to the first bit"
			operand: "R0X"
			function: (r,n,x) -> @store_register(r, @rot_value(@read_register(r), x))
		0xB:
			description: "JUMP to the instruction located in the memory cell at address XY if the contents of register R is equal to the contents of register 0"
			operand: "RXY"
			function: (r,x,y) -> if @read_register(r) == @read_register(0) then @jump(@join_nibbles(x,y))
		0xC:
			description: "HALT execution"
			operand: "000"
			function: () -> @halt()
		0xD:
			description: "LOAD the contents of memory cell at the address in register S into register R"
			operand: "0RS"
			function: (n,r,s) ->[a_1,a_2] = @split_byte(@read_register(s)); @store_register(r,@read_memory(a_1, a_2))
		0xE:
			description: "STORE the contents of register R in the memory cell at the address in register S"
			operand: "0RS"
			function: (n,r,s) -> @store_memory(read_register(r), read_register(s))
		0xF:
			description: "JUMP to the instruction located in the memory cell at address XY if the contents of register R is lower than or equal to the contents of register 0"
			operand: "RXY"
			function: (r,x,y) -> if @read_register(r) <= @read_register(0) then @jump(@read_memory(x,y))

if exports?
	exports.SimpleMachine = SimpleMachine
	assemble = require('./parser.coffee').assemble
	s = new SimpleMachine
	fs = require 'fs'
	asm = fs.readFileSync('./example.asm').toString()
	b = assemble asm
	console.log("Assembly: " + b)
	s.load b
	s.run()
	console.log("Registers: " + s.registers)
	console.log("Memory: ")

	for row in s.memory
		console.log row

else if window?
	window.SimpleMachine = SimpleMachine
