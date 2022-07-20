defmodule Elph.MixProject do
  use Mix.Project

  def project do
    [
      app: :elph,
      version: "0.9.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      description: description(),
      package: package(),
      deps: deps(),
      preferred_cli_env: [
        test: :test,
        "test.setup": :test
      ],
      test_coverage: [summary: [threshold: 0]]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    """
    A simple and customizable content management system.
    """
  end

  defp package do
    [
      maintainers: ["Naymspace"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/naymspace/elph",
        "Docs" => "https://hexdocs.pm/elph/"
      }
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.8"},
      {:file_info, "~> 0.0.4"},
      {:gettext, "~> 0.19"},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.5"},
      {:ffmpex, "~> 0.10.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 0.1", only: [:dev, :test], runtime: false},
      {:myxql, ">= 0.0.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.seed": ["run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test.setup": ["ecto.drop", "ecto.create --quiet", "ecto.migrate"]
    ]
  end
end
