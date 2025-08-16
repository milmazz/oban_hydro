defmodule ObanHydro.MixProject do
  use Mix.Project

  @source_url "https://github.com/milmazz/oban_hydro"
  @version "0.1.0"

  def project do
    [
      app: :oban_hydro,
      version: @version,
      name: "Oban Hydro",
      source_url: @source_url,
      homepage_url: @source_url,
      description: description(),
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      escript: escript(),
      docs: docs(),
      package: package()
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def escript do
    [main_module: ObanHydro.CLI]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.38", only: :dev, runtime: false, warn_if_outdated: true},
      {:oban, "~> 2.20", only: [:test]}
    ]
  end

  defp description,
    do: """
    Admin scripts to keep your Oban Workers sane
    """

  defp docs,
    do: [
      extras: [
        "CHANGELOG.md": [],
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme"
    ]

  defp package,
    do: [
      links: %{
        "Changelog" => "https://hexdocs.pm/oban_hydro/changelog.html",
        "GitHub" => @source_url
      },
      maintainers: ["Milton Mazzarri"],
      licenses: ["Apache-2.0"]
    ]
end
