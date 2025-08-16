defmodule ObanHydroTest do
  use ExUnit.Case
  doctest ObanHydro

  @source_beam "_build/test/lib/oban_hydro/ebin"

  alias ObanHydro.EmailDeliver

  test "group workers by the given queues" do
    assert %{"email_delivery" => [EmailDeliver]} ==
             ObanHydro.workers_by_queues(:email_delivery, @source_beam)
  end

  test "find and group workers by custom unique periods" do
    assert %{60 => [EmailDeliver]} == ObanHydro.unique_workers_with_custom_period(@source_beam)
  end

  test "find unique workers without the `keys` option" do
    assert [EmailDeliver] == ObanHydro.unique_workers_without_keys_option(@source_beam)
  end

  test "find and group workers by unique group states" do
    assert [{states, [EmailDeliver]}] =
             @source_beam
             |> ObanHydro.workers_by_unique_state_groups()
             |> Map.to_list()

    expected_states = MapSet.new(~w|scheduled available executing|a)
    assert states |> MapSet.new() |> MapSet.equal?(expected_states)
  end

  test "find workers without an enqueue wrapper function" do
    assert %{["enqueue"] => [EmailDeliver]} == ObanHydro.workers_without_wrappers(@source_beam)

    assert %{["schedule"] => [EmailDeliver]} ==
             ObanHydro.workers_without_wrappers(@source_beam, names: ["schedule"])

    assert %{["enqueue", "prepare"] => [EmailDeliver]} ==
             ObanHydro.workers_without_wrappers(@source_beam, names: ["enqueue", "prepare"])
  end
end
