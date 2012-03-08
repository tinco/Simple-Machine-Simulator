vows = require 'vows'
assert = require 'assert'

# Require machine globally
for k,v of require '../parser.coffee'
	global[k] = v

vows.describe('Simple ASM Parser')
.addBatch(
	'parsing statements' :
		'load statement' :
			'register with contents of memory cell' : ->
				assert.deepEqual(assemble('load R1,[FF]'),[0x11,0xFF])
			'register with value' : ->
				assert.deepEqual(assemble('load R1,FF'),[0x21,0xFF])
			'register with contents of memory cell in register' : ->
				assert.deepEqual(assemble('load R1,[R2]'),[0xD0,0x12])
		'store statement' : ->
			assert.deepEqual(assemble('store R1,[FF]'),[0x31,0xFF])
)
.export(module)
