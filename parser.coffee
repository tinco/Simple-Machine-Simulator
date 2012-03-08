# Parses an assembler string into an array of bytes
assemble = (string, offset) ->
	assembly = []
	labels = {}
	offset = 0 unless offset?
	
	parse_line = (line) ->
		[label, rest] = line.split(':') #TODO Breaks string
		if rest
			labels[label] = assembly.length + offset
		else
			rest = label
		parse_statement rest.split(';')[0] #TODO Breaks string

	parse_statement = (statement) ->
		if not statement then return
		[instruction, operand...] = statement.match(/[^\s|=|,]+/g)
		#console.log 'instruction: ' + instruction + ' operand: ' + operand
		switch instruction
			when "load"
				register = parse_register(operand[0])
				if (address = parse_address(operand[1]))?
					if (s = parse_register(address))?
						assembly.push join_nibbles(0xD, 0)
						assembly.push join_nibbles(register, s)
					else
						assembly.push join_nibbles(1, register)
						assembly.push parse_pattern(address)
				else if (pattern = parse_pattern(operand[1]))?
					assembly.push join_nibbles(2, register)
					assembly.push pattern
			when "store"
				register = parse_register(operand[0])
				address = parse_value parse_address(operand[1])
				assembly.push join_nibbles(3, register)
				assembly.push address
			when "move"
				r = parse_register(operand[1])
				s = parse_register(operand[0])
				assembly.push join_nibbles(4,0)
				assembly.push join_nibbles(s,r)
			when "addi"
				[r,s,t] = (parse_register(r) for r in operand)
				assembly.push join_nibbles(5, r)
				assembly.push join_nibbles(s,t)
			when "addf"
				[r,s,t] = (parse_register(r) for r in operand)
				assembly.push join_nibbles(6, r)
				assembly.push join_nibbles(s,t)
			when "or"
				[r,s,t] = (parse_register(r) for r in operand)
				assembly.push join_nibbles(7, r)
				assembly.push join_nibbles(s,t)
			when "and"
				[r,s,t] = (parse_register(r) for r in operand)
				assembly.push join_nibbles(8, r)
				assembly.push join_nibbles(s,t)
			when "xor"
				[r,s,t] = (parse_register(r) for r in operand)
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
				t = parse_pattern(operand[0])
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
		match = operand.match /[R|r]([0-9a-fA-F])/
		register = match[1] if match?
		parse_value(register) if register?

	parse_pattern = (operand) ->
		match = operand.match /^[0-9a-fA-F]{1,2}/
		pattern = match[0] if match?
		if pattern
			parse_value(pattern)
		else
			match = operand.match /\w+/
			match[0] if match?

	parse_address = (operand) ->
		match = operand.match /\[(.*)\]/
		match[1] if match?

	parse_data = (data) ->
		match = data.match /(".*"|[0-9a-fA-F]{1,2})/g
		for operand in match
			if operand[0] == '"'
				assembly.push(operand.charCodeAt(i)) for v,i in operand[1..-1]
			else
				assembly.push parse_value(operand)

	parse_value = (value) ->
		parseInt('0x' + value)

	join_nibbles = (x, y) -> x << 4 | y

	for line in string.split('\n')
		parse_line line
	
	#console.log 'assembly: ' + (b.toString(2) for b in assembly)

	# Patch in the labels
	for byte,i in assembly
		if byte.length? #is string
			assembly[i] = labels[byte]

	assembly

if exports?
	exports.assemble = assemble

if window?
	window.SimpleParser = {}
	window.SimpleParser.assemble = assemble
