defmodule Steve.MixProject do
  use Mix.Project

  def project do
    [
      app: :steve,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: "An Elixir job processor.",
      source_url: "https://github.com/satom99/steve",
    ]
  end

  def application do
    [
      mod: {Steve, []},
      start_phases: [queues: []]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.1"},
      {:ecto_sql, "~> 3.1"},
      {:poolboy, "~> 1.5"},
      {:ex_doc, "~> 0.21.1", only: :dev}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Santiago Tortosa"],
      links: %{"GitHub" => "https://github.com/satom99/steve"}
    ]
  end

  defp docs do
    [
      main: "overview",
      extras: [
        "docs/Overview.md"
      ],
      groups_for_extras: [
        "Introduction": ~r/docs\/.?/
      ]
    ]
  end
end