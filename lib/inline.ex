defmodule Inline do
  @moduledoc """
  Documentation for `Inline`.
  """

  defmacro test(actual, [do: expected]) do
    if Mix.env() == :test do
      {name, meta} = create_meta_info(__CALLER__)
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
