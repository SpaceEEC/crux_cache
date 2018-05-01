defmodule Crux.Cache.MixProject do
  use Mix.Project

  def project do
    [
      start_permanent: Mix.env() == :prod,
      package: package(),
      app: :crux_cache,
      version: "0.1.0",
      elixir: "~> 1.6",
      description: "Package providing Discord API struct caches for crux.",
      source_url: "https://github.com/SpaceEEC/crux_cache/",
      homepage_url: "https://github.com/SpaceEEC/crux_cache/",
      deps: deps()
    ]
  end

  def package do
    [
      name: :crux_cache,
      licenses: ["MIT"],
      maintainers: ["SpaceEEC"],
      links: %{
        "GitHub" => "https://github.com/SpaceEEC/crux_cache/",
        "Docs" => "https://hexdocs.pm/crux_cache/"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Crux.Cache.Application, []}
    ]
  end

  defp deps do
    [
      {:crux_structs, "~> 0.1.0"},
      {:credo, "~> 0.9.2", only: [:dev, :test], runtime: false},
      {:ex_doc, git: "https://github.com/spaceeec/ex_doc", only: :dev}
    ]
  end
end
