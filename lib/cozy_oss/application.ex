defmodule CozyOSS.Application do
  use Application

  require Logger

  def start(_type, _args) do
    CozyOSS.ApiClient.init()

    children = []

    opts = [strategy: :one_for_one, name: CozyOSS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
