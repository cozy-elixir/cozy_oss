defmodule CozyOSS.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "SDK builder for RESTful API of Aliyun OSS / Alibaba Cloud OSS."
  @source_url "https://github.com/cozy-elixir/cozy_oss"

  def project do
    [
      app: :cozy_oss,
      version: @version,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      package: package(),
      aliases: aliases()
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
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:finch, "~> 0.13", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: @version
    ]
  end

  defp package do
    [
      exclude_patterns: [],
      licenses: ["Apache-2.0"],
      links: %{GitHub: @source_url}
    ]
  end

  defp aliases do
    [publish: ["hex.publish", "tag"], tag: &tag_release/1]
  end

  defp tag_release(_) do
    Mix.shell().info("Tagging release as #{@version}")
    System.cmd("git", ["tag", @version])
    System.cmd("git", ["push", "--tags"])
  end
end
