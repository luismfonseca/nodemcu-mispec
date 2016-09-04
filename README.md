# nodemcu-mispec
Minimal Lua spec framework for NodeMCU.

## But, why?
There are several Lua spec frameworks, some as simple as this one but this one is different - its mine.
Also, being coupled to NodeMCU allows it to be a possibly better framework (i.e. async implementation of eventually).

## Usage, by example:

```lua
require 'mispec'

mispec.describe('A module', function(it)
    it:should('have a test', function()
      print('this is the body of the test')
      ok(1 == 1, 'one is equal to one')
      ok(eq(true, true))
      
      eventually(function() -- will run this up to 10 times, with 300ms pauses between failures
        ok(math.random(10) < 7)
      end)
      
      eventually(ko, 5, 1000) -- 5 times with 1s pauses it will run ko and fail
      
      eventually(ok) -- although it's possible to have several eventualities, execution order is not garanteed
      
      ok(true) -- this will also be executed potentially before those eventualities have passed
    end)
    
    it:should('have multiple tests', ok) -- they will be executed sequentially
):evaluate() -- run it!
```

## Contributing

Feel free to create issues and merge requests - I will ignore them and accept them, respectively.

*"mi spec es su spec".*
