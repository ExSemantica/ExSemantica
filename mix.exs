# >>> Mix file for installing the libraries
# Copyright 2023 Roland Metivier <metivier.roland@chlorophyt.us>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Exsemantica.MixProject do
  use Mix.Project

  def project do
    [
      app: :exsemantica,
      version: "0.9.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Exsemantica.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # RATIONALE: HTTP connection handling to the API
      {:plug_cowboy, "~> 2.6"},

      # RATIONALE: The API uses JSON
      {:jason, "~> 1.4"},

      # RATIONALE: Handle transliteration of usernames
      {:unidecode, "~> 1.0"},

      # RATIONALE: Store into a PostgreSQL database
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17.1"},

      # RATIONALE: Password hashing
      {:argon2_elixir, "~> 3.1"},

      # RATIONALE: By using these tools the code can be better-formed
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp aliases do
    [ 
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
