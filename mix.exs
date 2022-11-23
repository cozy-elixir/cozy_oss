defmodule CozyOSS.MixProject do
  use Mix.Project

  def project do
    [
      app: :cozy_oss,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CozyOSS.Application, []},
      env: [api_client: CozyOSS.ApiClient.Finch]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sax_map, "~> 1.0"},
      {:finch, "~> 0.13", only: [:dev, :test]}
    ]
  end
end
