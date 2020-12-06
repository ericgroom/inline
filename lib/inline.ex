defmodule Inline do
  @moduledoc """
  Documentation for `Inline`.
  """

  defmacro test(clause, [do: expr]) do
    if Mix.env() == :test do
      %{module: module, file: file, line: line} = __CALLER__
      name = :"__inline__test__#{line}"
      meta = %{module: module, file: file, line: line, name: name} |> Macro.escape()
      quote do
        if not Module.has_attribute?(__MODULE__, :inline_test_meta) do
          Module.register_attribute(__MODULE__, :inline_test_meta, accumulate: true, persist: true)
        end
        @inline_test_meta unquote(meta)
        def unquote(name)() do
          {unquote(clause), unquote(expr)}
        end
      end
    end
  end

  defmacro inline(context) do
    quote bind_quoted: [context: context] do
      for inline_test <- Inline.Helpers.extract_tests(context) do
        env_mod = __ENV__.module
        hack = Map.put(inline_test, :module, env_mod)
        test = ExUnit.Case.register_test(hack, :inline, "#{inline_test.name}", [])
        def unquote(test)(_) do
          {actual, expected} = apply(unquote(inline_test.module), unquote(inline_test.name), [])
          assert actual == expected
        end
      end
    end
  end
end
