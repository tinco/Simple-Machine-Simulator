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
	'operations' :
		'topic' : new SimpleMachine()
		'join_nibbles' :
			'should work with the first bit and the last bit set' :
				(topic) -> assert.equal(topic.join_nibbles(8,1), 0x81)
			'should work with all bits set' :
				(topic) -> assert.equal(topic.join_nibbles(0xF,0xF),0xFF)
			'should work in another case' :
				(topic) -> assert.equal(topic.join_nibbles(5,0xA), 0x5A)
		'split_byte' :
			'should work with the first bit and the last bit set' :
				(topic) -> assert.deepEqual(topic.split_byte(0x81),[8,1])
			'should work with all bits set' :
				(topic) -> assert.deepEqual(topic.split_byte(0xFF),[0xF,0xF])
			'should work in another case' :
				(topic) -> assert.deepEqual(topic.split_byte(0x5A),[5,0xA])
		'rot_value' :
			'should work with the first bit and the last bit set' :
				(topic) -> assert.equal(topic.rot_value(0x81),0xC0)
			'should work with all bits set' :
				(topic) -> assert.equal(topic.rot_value(0xFF),0xFF)
			'should work in another case' :
				(topic) -> assert.equal(topic.rot_value(0x5A),0x2D)
)
.export(module)
