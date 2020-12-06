defmodule Inline.MixProject do
  use Mix.Project

  def project do
    [
      app: :inline,
      version: "0.1.0",
      elixir: "~> 1.10",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def deps() do
    [
      {:ex_doc, "~> 0.23", only: :dev},
    ]
  end

  def description() do
    """
    Inline is a tiny testing library for helping you develop faster.
    """
  end

  @github "https://github.com/ericgroom/inline"

  def package() do
    [
      licenses: ["MIT"],
      links: %{github: @github},
      source_url: @github,
      homepage_url: @github
    ]
  end
end
