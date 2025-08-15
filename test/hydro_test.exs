defmodule HydroTest do
  use ExUnit.Case
  doctest Hydro

  @app Hydro.MixProject.project()[:app]

  alias Hydro.EmailDeliver

  test "group workers by the given queues" do
    assert %{"email_delivery" => [EmailDeliver]} ==
             Hydro.workers_by_queues(:email_delivery, @app)
  end

  test "find and group workers by custom unique periods" do
    assert %{60 => [EmailDeliver]} == Hydro.unique_workers_with_custom_period(@app)
  end

  test "find unique workers without the `keys` option" do
    assert [EmailDeliver] == Hydro.unique_workers_without_keys_option(@app)
  end

  test "find and group workers by unique group states" do
    assert [{states, [EmailDeliver]}] =
             @app
             |> Hydro.workers_by_unique_state_groups()
             |> Map.to_list()

    expected_states = MapSet.new(~w|scheduled available executing|a)
    assert states |> MapSet.new() |> MapSet.equal?(expected_states)
  end

  test "find workers without an enqueue wrapper function" do
    assert [EmailDeliver] == Hydro.workers_without_wrappers(@app)
    assert [EmailDeliver] == Hydro.workers_without_wrappers(@app, prefixes: ["schedule"])
  end
end
