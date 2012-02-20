class SimpleMachine
	constructor: () ->
		# Initialize the registers and the memory with 0's
		@registers = (0 for num in [1..16])
		# The memory is a 16x16 array
		@memory = ((0 for num in [1..16]) for x in [1..16])
		@program = []
		#program starts at A0
		@program_counter = 0xA0

	run: () ->
		halting = false
		while not halting
			statement = @program[@program_counter]
			@instructions[statement[0]].function.apply(this, statement[1..3])
			halting = statement[0] == 0xC #HALT
			@program_counter += 1

	read_register: (r) -> @registers[r]
	read_memory: (x, y) -> @memory[x][y]
	store_register: (r, value) -> @registers[r] = value
	store_memory: (x, y, value) -> @memory[x][y] = value
	join_bytes: (x, y) -> x << 8 | y
	add_integers: (x,y) -> x + y
	add_floats: (x,y) -> 0 # figure out
	or_values: (x,y) -> x | y
	and_values: (x,y) -> x & y
	xor_values: (x,y) -> x ^ y
	rot_value: (v,x) -> v >> 1 | (v & 1 << 31)
	jump: (x) -> @program_counter = x - 1 # will be executed next step
	halt: () -> #do nothing

	instructions:
		1:
			description: "LOAD register R with contents of memorycell XY"
			operand: "RXY"
			function: (r,x,y) -> @store_register(r, @read_memory(x,y,))
		2:
			description: "LOAD register R with value XY"
			operand: "RXY"
			function: (r,x,y) -> @store_register(r, @join_bytes(x,y))
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
