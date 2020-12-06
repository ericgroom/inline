defmodule Inline.Helpers do
  @moduledoc false

  def extract_tests(module) when is_atom(module) do
    module.module_info(:attributes)
    |> Keyword.get_values(:inline_test_meta)
    |> List.flatten()
  end

  def extract_tests([application: application]) do
    {:ok, modules} = :application.get_key(application, :modules)

    modules
    |> Enum.map(&extract_tests/1)
    |> List.flatten()
  end
end
