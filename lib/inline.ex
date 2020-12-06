defmodule Inline do
  @moduledoc """
  Documentation for `Inline`.
  """

  defmacro test(actual, [do: expected]) do
    if testing?() do
      {name, meta} = create_meta_info(__CALLER__)
      quoted_assertion_test(actual, expected, name, meta)
    end
  end

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
