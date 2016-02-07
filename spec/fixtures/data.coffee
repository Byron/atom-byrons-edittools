ExampleBlock = require '../utils/example-block'

v = null
data =
  rustFn:
    function:
      _0fn: v
      _1name: v
      _2arguments:
        1:
          'mut x': v
        2:
          u32: v
          usize: v
      _return:
        u8: v
      body:
        '42': v

sequenceCheck =
  rustFn:  "function|_0fn|_1name|_2arguments|1|mut x|2|u32|usize|_return|u8|\
            body|42"

(verifyIntegrity = ->
  for name, structure of data
    data[name] = sequence = ExampleBlock.makeSequenceDF structure

    want = sequenceCheck[name] or "<set sequence check for #{name}"
    have = (b[b.length-1] for b in sequence when b.length > 0).join('|')
    if want != have
      console.log "HAVE - WANT:\n#{have}\n#{want}"
      throw new Error("unexpected sequence - please adjust expectation and/or
      sequence. See log for info.")
  )()

module.exports = data
