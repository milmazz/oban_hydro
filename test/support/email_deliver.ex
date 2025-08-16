defmodule ObanHydro.EmailDeliver do
  @moduledoc """
  Dummy Worker

  According with the [Scaling Applications guide][scaling] this unique worker has some problems:

  * Defines a custom `period` of time, usually you want to set `:infinity` instead.
  * The list of states is missing the `retryable` state, which is an usual mistake.
    - Instead of using the list of states, use "Unique Group States" (since Oban [v2.20.0])
  * This unique worker doesn't define the `keys` option. 

  [v2.20.0]: https://github.com/oban-bg/oban/releases/tag/v2.20.0
  [scaling]: https://hexdocs.pm/oban/scaling.html#uniqueness
  """
  use Oban.Worker,
    queue: :email_delivery,
    unique: [
      period: div(to_timeout(minute: 1), 1000),
      states: [:scheduled, :available, :executing]
    ]

  def perform(_), do: :ok
end
