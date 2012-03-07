vows = require 'vows'
assert = require 'assert'

# Require machine globally
for k,v of require '../machine.coffee'
	global[k] = v

vows.describe('SimpleMachine')
.addBatch(
	'a new simple machine' :
		'topic' : new SimpleMachine()
		'has REGISTERS registers' : (topic) ->
			assert.equal(topic.registers.length, REGISTERS)
		'has MEMORY_HEIGHT rows of memory' : (topic) ->
			assert.equal(topic.memory.length, MEMORY_HEIGHT)
		'has MEMORY_WIDTH columns of memory' : (topic) ->
			assert.equal(topic.memory[0].length, MEMORY_WIDTH)
		'is halted' : (topic) ->
			assert.equal(topic.halted, true)
)
.export(module)
