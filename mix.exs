defmodule Crux.Cache.MixProject do
  use Mix.Project

  @vsn "0.1.0"
  @name :crux_cache

  def project do
    [
      start_permanent: Mix.env() == :prod,
      package: package(),
      app: @name,
      version: @vsn,
      elixir: "~> 1.6",
      description: "Package providing Discord API struct caches for crux.",
      source_url: "https://github.com/SpaceEEC/#{@name}/",
      homepage_url: "https://github.com/SpaceEEC/#{@name}/",
      deps: deps()
    ]
  end

  def package do
    [
      name: @name,
      licenses: ["MIT"],
      maintainers: ["SpaceEEC"],
      links: %{
        "GitHub" => "https://github.com/SpaceEEC/#{@name}/",
        "Changelog" => "https://github.com/SpaceEEC/#{@name}/releases/tag/#{@vsn}/",
        "Documentation" => "https://hexdocs.pm/#{@name}/",
        "Unified Development Documentation" => "https://crux.randomly.space/"
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
      {:crux_structs, "~> 0.1.4"},
      {:credo, "~> 0.9.2", only: [:dev, :test], runtime: false},
      {:ex_doc, git: "https://github.com/spaceeec/ex_doc", only: :dev}
    ]
  end
end
