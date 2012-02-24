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
			[c_1, c_2] = @split_byte(@program_counter)
			# Split cells into instruction register fields (which are 4-bits)
			@instruction_register = @split_byte(@memory[c_1][c_2]).concat(@split_byte(@memory[c_1][c_2 + 1]))
			# Execute function of instruction
			@instructions[@instruction_register[0]].function.apply(this, @instruction_register[1..3])
			halting = @instruction_register[0] == 0xC #HALT
			@increase_program_counter()

	increase_program_counter: () ->
		# A instruction is 2 bytes (4 nibbles)
		@program_counter += 2

	# Parses an assembler string into an array of bytes
	assemble: (string) ->
		assembly = []
		labels = {}
		offset = 0xA0
		
		parse_line = (line) ->
			[label, rest] = line.split(':')
			if rest
				labels[label] = assembly.length + offset
			else
				rest = label
			parse_statement rest.split(';')[0]

		parse_statement = (statement) ->
			if not statement then return
			[instruction, operand...] = statement.split(/[\W+|=|,]+/)
			switch instruction
				when "load"
					register = parse_register(operand[0])
					if address = parse_address(operand[1])
						assembly.push join_nibbles(1, register)
						assembly.push address
					else if pattern = parse_pattern(operand[1])
						assembly.push join_nibbles(2, register)
						assembly.push pattern
				when "store"
					register = parse_register(operand[0])
					address = parse_address(operand[1])
					assembly.push join_nibbles(3, register)
					assembly.push address
				when "move"
					r = parse_register(operand[1])
					s = parse_register(operand[0])
					assembly.push join_nibbles(4,0)
					join_nibbles(s,r)
				when "addi"
					[r,s,t] = parse_register(r) for r in operand
					assembly.push join_nibbles(5, r)
					assembly.push join_nibbles(s,t)
				when "addf"
					[r,s,t] = parse_register(r) for r in operand
					assembly.push join_nibbles(6, r)
					assembly.push join_nibbles(s,t)
				when "or"
					[r,s,t] = parse_register(r) for r in operand
					assembly.push join_nibbles(7, r)
					assembly.push join_nibbles(s,t)
				when "and"
					[r,s,t] = parse_register(r) for r in operand
					assembly.push join_nibbles(8, r)
					assembly.push join_nibbles(s,t)
				when "xor"
					[r,s,t] = parse_register(r) for r in operand
					assembly.push join_nibbles(9, r)
					assembly.push join_nibbles(s,t)
				when "ror"
					r = parse_register(operand[0])
					x = parseInt(operand[1])
					assembly.push join_nibbles(0xA,r)
					assembly.push x
				when "jmpEQ"
					r = parse_register(operand[0])
					t = parse_pattern(operand[2])
					assembly.push join_nibbles(0xB,r)
					assembly.push t
				when "jmpLE"
					r = parse_register(operand[0])
					t = parse_pattern(operand[2])
					assembly.push join_nibbles(0xF,r)
					assembly.push t
				when "jmp"
					t = parse_pattern(operand[1])
					assembly.push join_nibbles(0xB,0)
					assembly.push t
				when "halt"
					assembly.push join_nibbles(0xC,0)
					assembly.push 0
				when "db"
					[before, data] = statement.split "db"
					parse_data data	
				else
					#syntax error !?!$?#!?$!

		parse_register = (operand) ->
			match = operand.match /[R|r](\d+)/
			register = match[1] if match
			parse_value(register) if register

		parse_pattern = (operand) ->
			match = operand.match /[0-9a-fA-F]+/
			pattern = match[0] if match
			if pattern
				parse_value(pattern)
			else
				match = operand.match /\w+/
				match[0] if match

		parse_address = (operand) ->
			match = operand.match /\[([0-9a-fA-F]+)\]/
			[m, address] = match if match
			parse_value(address) if address

		parse_data = (data) ->
			match = data.match /(".*"|\d+)/g
			for operand in match
				if operand[0] == '"'
					assembly.push(operand.charCodeAt(i)) for v,i in operand[1..-2]
				else
					assembly.push parse_value(operand)

		parse_value = (value) ->
			parseInt('0x' + value)

		join_nibbles = @join_nibbles

		for line in string.split('\n')
			parse_line line

		# Patch in the labels
		for byte,i in assembly
			if byte.length? #is string
				assembly[i] = labels[byte]

		assembly

	# Reads an assembly as an array of bytes into memory from offset 0xA0
	load: (assembly) ->
		for byte, i in assembly
			[i_1, i_2] = @split_byte(i)
			@memory[i_1 + 0xA][i_2] = byte

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
		0xD:
			description: "LOAD the contents of memory cell at the address in register S into register R"
			operand: "0RS"
			function: (r,s) -> @store_register(r,@read_memory(read_register(s)))
		0xE:
			description: "STORE the contents of register R in the memory cell at the address in register S"
			operand: "0RS"
			function: (r,s) -> @store_memory(read_register(r), read_register(s))
		0xF:
			description: "JUMP to the instruction located in the memory cell at address XY if the contents of register R is lower than or equal to the contents of register 0"
			operand: "RXY"
			function: (r,x,y) -> if @read_register(r) <= @read_register(0) then @jump(@read_memory(x,y))

exports.SimpleMachine = SimpleMachine

s = new SimpleMachine
b = s.assemble("load r1,1\nhalt")
s.load b
s.run()
console.log("Assembly: " + b)
console.log("Registers: " + s.registers)
console.log("Assembly: ")
for row in s.memory
	console.log row
