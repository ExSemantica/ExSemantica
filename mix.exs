defmodule ExSemantica.MixProject do
  use Mix.Project

  def project do
    [
      app: :exsemantica,
      version: "0.9.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExSemantica.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:unidecode, "~> 1.0"},
      {:jason, "~> 1.3"}
    ]
  end
end
