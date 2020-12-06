defmodule Inline.MixProject do
  use Mix.Project

  def project do
    [
      app: :inline,
      version: "0.1.0",
      elixir: "~> 1.10",
      deps: deps()
    ]
  end

  def deps() do
    [
      {:ex_doc, "~> 0.23", only: :dev},
    ]
  end
end
