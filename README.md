# nodemcu-mispec
Minimal Lua spec framework for NodeMCU.

## But, why?
There are several Lua spec frameworks, some as simple as this one but this one is different - its mine.
Also, being coupled to NodeMCU allows it to be a possibly better framework (i.e. async implementation of eventually).

## Usage, by example:

```lua
require 'mispec'

describe('A module', function(it)
    it:should('have a test', function()
      print('this is the body of the test')
      ok(1 == 1, 'one is equal to one')
      ok(eq(true, true)) -- the eq function does a deep comparison

      eventually(function() -- will run this up to 10 times, with 300ms pauses between failures
        ok(math.random(10) < 7)
      end)
      
      andThen(function() -- after the first eventually, this is necessary to chain events
        ok(true)
      end)

      eventually(ko, 5, 1000) -- runs 5 times with 1s pauses, but fails since it's ko

      -- any code here would be executed before the eventually/andThen!
    end)
    
    it:should('have multiple tests', ok) -- they will be executed sequentially
)

mispec.run()
```

And here's an example output:
```lua
A mispec module, it should:
>
  * run a test
  * run multiple tests
  * run a test that eventually passes
  * run a test that has several eventuallys
  * run a test that has several eventuallys in the correct order
  * run a test with andThen function to chain logic
  * run a test that just fails
  ' it failed:  mispec.lua:12: expression is not ko
stack traceback:
  mispec.lua:12: in function 'ok'
  mispec.lua:21: in function <mispec.lua:16>
  [C]: in function 'pcall'
  mispec.lua:100: in function <mispec.lua:98>


Completed in 3.36 seconds.
```


## Credits

 * Serge Zaitsev, who wrote the eq function in [gambiarra](https://bitbucket.org/zserge/gambiarra/src/10c86d15d11908d24516495a4eb27049a257d6d7?at=default)

## Contributing

Feel free to create issues and merge requests - I will ignore them and accept them, respectively.

*"mi spec es su spec".*
