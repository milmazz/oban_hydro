defmodule ObanHydro.CLITest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias ObanHydro.CLI

  @source_beam "_build/test/lib/oban_hydro/ebin"

  test "group workers by the given queues" do
    assert capture_io(fn ->
             CLI.main(~w|workers_by_queues #{@source_beam} -q email_delivery|)
           end) == ~s|"email_delivery":\n\tObanHydro.EmailDeliver\n|
  end

  test "find and group workers by custom unique periods" do
    assert capture_io(fn ->
             CLI.main(~w|unique_workers_with_custom_period #{@source_beam}|)
           end) == ~s|60:\n\tObanHydro.EmailDeliver\n|
  end

  test "find unique workers without the `keys` option" do
    assert capture_io(fn ->
             CLI.main(~w|unique_workers_without_keys_option #{@source_beam}|)
           end) == ~s|ObanHydro.EmailDeliver\n|
  end

  test "find and group workers by unique group states" do
    assert capture_io(fn ->
             CLI.main(~w|workers_by_unique_state_groups #{@source_beam}|)
           end) == ~s|[:available, :executing, :scheduled]:\n\tObanHydro.EmailDeliver\n|
  end

  test "find workers without wrapper functions" do
    assert capture_io(fn ->
             CLI.main(~w|workers_without_wrappers #{@source_beam} --name schedule|)
           end) == ~s|["schedule"]:\n\tObanHydro.EmailDeliver\n|

    assert capture_io(fn ->
             CLI.main(~w|workers_without_wrappers #{@source_beam}|)
           end) == ~s|["enqueue"]:\n\tObanHydro.EmailDeliver\n|
  end

  test "prints version" do
    assert capture_io(fn ->
             CLI.main(~w|--version|)
           end) == ~s|ObanHydro v0.1.1-dev\n|

    assert capture_io(fn ->
             CLI.main(~w|-v|)
           end) == ~s|ObanHydro v0.1.1-dev\n|
  end

  test "prints help" do
    assert capture_io(fn ->
             CLI.main(~w|--help|)
           end) =~ ~s|Usage:\n  oban_hydro COMMAND BEAMS [OPTIONS]\n|

    assert capture_io(fn ->
             CLI.main(~w|-h|)
           end) =~ ~s|Usage:\n  oban_hydro COMMAND BEAMS [OPTIONS]\n|
  end

  test "prints usage when option queues is empty" do
    assert capture_io(fn ->
             CLI.main(~w|workers_by_queues #{@source_beam}|)
           end) =~ ~s|Usage:\n  oban_hydro COMMAND BEAMS [OPTIONS]\n|
  end

  test "prints usage when number of arguments is different than two" do
    assert capture_io(fn ->
             CLI.main(~w|workers_without_wrappers #{@source_beam} foo|)
           end) =~ ~s|Usage:\n  oban_hydro COMMAND BEAMS [OPTIONS]\n|

    assert capture_io(fn ->
             CLI.main(~w|workers_without_wrappers|)
           end) =~ ~s|Usage:\n  oban_hydro COMMAND BEAMS [OPTIONS]\n|
  end

  test "prints usage when given command is invalid" do
    output =
      capture_io(fn ->
        CLI.main(~w|foo bar|)
      end)

    assert output =~ ~s|Invalid arguments|
    assert output =~ ~s|Usage:\n  oban_hydro COMMAND BEAMS [OPTIONS]\n|
  end
end
