class SimpleMachine
	constructor: () ->
		# Initialize the registers and the memory with 0's
		@registers = (0 for num in [1..16])
		# The memory is a 16x16 array
		@memory = ((0 for num in [1..16]) for x in [1..16])
		#program starts at A0
		@program_counter = 0xA0
		@instruction_register = []

	run: () ->
		halting = false
		while not halting
			# Split address into array coordinates
			[c_1, c2] = @split_byte(@program_counter)
			# Split cells into instruction register fields (which are 4-bits)
			@instruction_register = @split_byte(@memory[c_1][c_2]).concat(@split_byte(@memory[c_1][c_2 + 1]))
			# Execute function of instruction
			@instructions[@instruction_register[0]].function.apply(this, @instruction_register[1..3])
			halting = statement[0] == 0xC #HALT
			@increase_program_counter()

	increase_program_counter: () ->
		# A instruction is 2 bytes (4 nibbles)
		@program_counter += 2

	# Parses an assembler string into an array of bytes
	assemble: (string) ->
		assembly = []
		labels = {}
		position = 0xA0
		
		parse_line = (line) ->
			[label, instruction] = line.split(':')
			if instruction then
				parse_label label
			else
				instruction = label
			parse_instruction instruction.split(';')[0]

		parse_instruction = (instruction) ->
			[instruction, rest...] = instruction.split(/(\W|=|,)+/)
			switch instruction
				when "load" then
				when "store" then
				when "move" then
				when "addi" then
				when "addf" then
				when "or" then
				when "and" then
				when "xor" then
				when "ror" then
				when "jmpEQ" then
				when "halt" then
				else
					#syntax error !?!$?@#!@?$!


		for line in string.split('\n')
			parse_line line
			position += 2

	# Reads an assembly as an array of bytes into memory from offset 0xA0
	load: (assembly) ->
		for statement, i in assembly
			[i_1, i_2] = split_byte(i * 2)
			@memory[i_1 + 0xA][i_2] = statement[0]
			@memory[i_1 + 0xA][i_2 + 1] = statement[1]

	##
	#  We have the implementations of the actions in seperate methods so we can hook them for step through representations
	##
	read_register: (r) -> @registers[r]
	read_memory: (x, y) -> @memory[x][y]
	store_register: (r, value) -> @registers[r] = value
	store_memory: (x, y, value) -> @memory[x][y] = value
	join_nibbles: (x, y) -> x << 4 | y
	split_byte: (v) -> [v >> 4, v & 0xF]
	add_integers: (x,y) -> x + y
	add_floats: (x,y) -> 0 # figure out
	or_values: (x,y) -> x | y
	and_values: (x,y) -> x & y
	xor_values: (x,y) -> x ^ y
	rot_value: (v,x) -> v >> 1 | (v & 1 << 7)
	jump: (x) -> @program_counter = x - 2 # will be executed next step
	halt: () -> #do nothing

	instructions:
		1:
			description: "LOAD register R with contents of memorycell XY"
			operand: "RXY"
			function: (r,x,y) -> @store_register(r, @read_memory(x,y,))
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
			function: (r,x,y) -> if @read_register(r) == @read_register(0) then @jump(@read_memory(x,y))
		0xC:
			description: "HALT execution"
			operand: "000"
			function: () -> @halt()

exports.SimpleMachine = SimpleMachine
exports.s = new SimpleMachine
