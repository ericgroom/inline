# Inline

**Inline is a tiny testing library for Elixir to help you develop faster**

Inline provides macros to test your code right beside your source code. This can be used
to help quickly prototype, or even just as permanent unit tests if you prefer this style

## Installation

Inline can be installed by adding `inline` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:inline, "~> 0.1.0"}
  ]
end
```

## Usage

Say you are writing a function which is used by some other functions, and you just want
to quickly test if it works or not before continuing

``` elixir
defmodule MathUtils do
  def some_operation(a, b), do: a + b
end
```

You can then quickly write a test using Inline like so:

``` elixir
defmodule MathUtils do
  import Inline

  test some_operation(1, 2), is: 3
  def some_operation(a, b), do: a + b
end
```

Inline uses ExUnit as a test runner, in order to register the test we can either register a particular module...

``` elixir
defmodule MathUtilsTest do
  use ExUnit.Case, async: true
  import Inline
  
  inline MathUtils
end
```

Or scan the entire application for tests

``` elixir
defmodule InlineTests do
  use ExUnit.Case, async: true
  import Inline
  
  inline application: :my_app
end
```

You should then be able to run `mix test`!

Additional usage information can be found from the [docs](https://hexdocs.pm/inline/Inline.html).
