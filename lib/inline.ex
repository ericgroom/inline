defmodule Inline do
  @moduledoc """
  # Overview
  Inline is a tiny testing library for helping you develop faster.

  The idea behind Inline is to help you develop faster, not completely replace
  your existing unit tests. You may even decide just to use Inline while experimenting
  and eventually convert your Inline tests into proper ExUnit cases.

  # Prerequisites
  Inline utilizes ExUnit as a test runner, so you should already have a testing
  enviornment set up before continuing. This is already set up for you if you just
  run `mix new` when creating a project.

  # Usage
  In order to create Inline tests there are just two steps:
  1. Writing the actual test
  2. Registering your test with ExUnit

  To write a test, you will use either the `Inline.test/2` or `Inline.test/1` macro.
  To register your test, you will use the `Inline.inline/1` macro within a ExUnit.Case.

  Once that's done, your tests can be run with `mix test` just like normal.
  """

  @doc """
  Creates an inline test based on an expected result.

  The test that will be created simply compares the two expressions
  produced at runtime.

  ## Example testing a function

      defmodule Foo do
        import Inline

        test add(1, 2), do: 3
        def add(a, b), do: a + b
      end

  ## Example with just expressions

      defmodule Bar do
        import Inline

        # It looks nice when you match function syntax, but any expression can be used for either side
        test 3, do: 3
      end
  """
  defmacro test(actual, expected)
  defmacro test(actual, [do: expected]) do
    if testing?() do
      {name, meta} = create_meta_info(__CALLER__)
      quoted_assertion_test(actual, expected, name, meta)
    end
  end

  @doc """
  Creates an inline test

  ## Examples

      defmodule Foo do
        import Inline

        test do
          assert add(1, 3) == 4
        end
        def add(a, b), do: a + b
      end
  """
  defmacro test(block)
  defmacro test([do: block]) do
    if testing?() do
      {name, meta} = create_meta_info(__CALLER__)
      quoted_block_test(block, name, meta)
    end
  end

  defp testing?(), do: Mix.env() == :test

  defp quoted_assertion_test(actual, expected, name, meta) do
    quote do
      if not Module.has_attribute?(__MODULE__, :inline_test_meta) do
        Module.register_attribute(__MODULE__, :inline_test_meta, accumulate: true, persist: true)
      end
      @inline_test_meta unquote(meta)
      def unquote(name)() do
        {unquote(actual), unquote(expected)}
      end
    end
  end

  defp quoted_block_test(block, name, meta) do
    quote do
      if not Module.has_attribute?(__MODULE__, :inline_test_meta) do
        Module.register_attribute(__MODULE__, :inline_test_meta, accumulate: true, persist: true)
      end
      @inline_test_meta unquote(meta)
      def unquote(name)() do
        import ExUnit.Assertions
        unquote(block)
      end
    end
  end

  defp create_meta_info(caller) do
    %{module: module, file: file, line: line} = caller
    name = :"__inline__test__#{line}"
    meta = %{module: module, file: file, line: line, name: name} |> Macro.escape()
    {name, meta}
  end

  @doc """
  Registers an inline test for running. Without calling this macro, your tests will never run!

  There are two main ways of registering tests:
  1. For a particular module (similar to the doctest macro)
  2. For an entire application

  The main advantage of running tests for the entire application is you won't need as many modifications
  made across your project to test new modules. The main disadvantage is your application must be started,
  so using `mix test --no-start` won't work.

  ## Single module example

  *in `lib/foo.ex`*
      defmodule Foo
        import Inline

        test four(), do: 4
        def four(), do: 4
      end

  *in `test/foo_test.exs`*
      defmodule FooTest do
        use ExUnit.Case, async: true
        import Inline

        inline Foo

        describe "four/0" do
          # rest of your tests...
        end
      end

  ## Entire application example
  *in `lib/foo.ex`*
      defmodule MyProject.Foo
        import Inline

        test four(), do: 4
        def four(), do: 4
      end

  *in `lib/bar.ex`*
      defmodule MyProject.Bar
        import Inline

        test five(), do: 5
        def five(), do: 5
      end

  *in `mix.exs`*
      defmodule MyProject.MixProject do
        use Mix.Project

        def project do
          [
            app: :my_project,
          ]
        end
      end

  *in `test/inline_test.exs` (can be named anything that ExUnit will pick up on (generally "*_test.exs"))
      defmodule MyProject.InlineTest do
        use ExUnit.Case, async: true
        import Inline

        inline application: :my_project
      end
  """
  defmacro inline(context) do
    quote bind_quoted: [context: context] do
      for inline_test <- Inline.Helpers.extract_tests(context) do
        # in order for ExUnit to work, the module passed here need to be one that uses ExUnit.Case
        # however all of the other info should be from the context of the test definition
        exunit_test = Map.put(inline_test, :module, __ENV__.module)
        test = ExUnit.Case.register_test(exunit_test, :inline, "#{inline_test.name}", [])
        def unquote(test)(_) do
          case apply(unquote(inline_test.module), unquote(inline_test.name), []) do
            {actual, expected} ->
              assert actual == expected
            block ->
              block
          end
        end
      end
    end
  end
end
