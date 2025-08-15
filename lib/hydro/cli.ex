defmodule Hydro.CLI do
  @moduledoc """
  CLI interface for Hydro
  """
  @version Hydro.MixProject.project()[:version]

  @aliases [
    h: :help,
    v: :version,
    q: :queue,
    n: :name
  ]

  @switches [
    help: :boolean,
    version: :boolean,
    queue: :keep,
    name: :keep
  ]

  @valid_commands ~w|
  workers_by_queues
  unique_workers_with_custom_period
  unique_workers_without_keys_option
  workers_by_unique_state_groups
  workers_without_wrappers
  |

  def main(args) do
    {opts, args, _invalid} = OptionParser.parse(args, aliases: @aliases, strict: @switches)

    cond do
      Keyword.has_key?(opts, :version) ->
        print_version()

      Enum.count_until(args, 3) == 2 ->
        [command, source_beam] = args
        process(command, source_beam, opts)

      true ->
        print_usage()
    end
  end

  defp process(command, source_beam, opts) when command in @valid_commands do
    command = String.to_existing_atom(command)
    process(command, source_beam, opts)
  end

  defp process(:workers_by_queues, app, opts) do
    queues = Keyword.get_values(opts, :queue)

    if queues == [] do
      print_usage()
    else
      queues
      |> Hydro.workers_by_queues(app)
      |> print_grouped_workers()
    end
  end

  defp process(:unique_workers_with_custom_period, app, []) do
    app
    |> Hydro.unique_workers_with_custom_period()
    |> print_grouped_workers()
  end

  defp process(:unique_workers_without_keys_option, app, []) do
    app
    |> Hydro.unique_workers_without_keys_option()
    |> Enum.map(&(&1 |> inspect() |> IO.puts()))
  end

  defp process(:workers_by_unique_state_groups, app, []) do
    app
    |> Hydro.workers_by_unique_state_groups()
    |> print_grouped_workers()
  end

  defp process(:workers_without_wrappers, app, opts) do
    names = Keyword.get_values(opts, :name)
    wrapper_names = (names == [] && ["enqueue"]) || names

    app
    |> Hydro.workers_without_wrappers(names: wrapper_names)
    |> print_grouped_workers()
  end

  defp process(_, _, _) do
    message = "Invalid arguments"
    message_formatted = IO.ANSI.format([:red, message, :reset])
    IO.puts(message_formatted)
    print_usage()
  end

  defp print_version, do: IO.puts("Hydro v#{@version}")

  defp print_usage do
    IO.puts("""
    Usage:
      hydro COMMAND BEAMS [OPTIONS]

    Examples:
      hydro workers_by_queues _build/dev/lib/my_app/ebin -q email --queue default
      hydro workers_without_wrappers _build/dev/lib/my_app/ebin -n enqueue --name prepare
      hydro unique_workers_with_custom_period _build/dev/lib/my_app/ebin
      hydro unique_workers_without_keys_option _build/dev/lib/my_app/ebin
      hydro workers_by_unique_state_groups _build/dev/lib/my_app/ebin

    Options:
      -v, --version Prints the Hydro version.
      -h, --help    Print this usage.
      -q, --queue   Specifies one or multiple Oban queues
      -n, --name    Indicates one or multiple Oban wrapper names
    """)
  end

  defp print_grouped_workers(grouped_workers) do
    grouped_workers
    |> Enum.map(fn {key, workers} ->
      modules = workers |> Enum.sort() |> Enum.map_join("\n\t", &inspect/1)
      IO.puts("#{inspect(key)}:\n\t#{modules}")
    end)
  end
end
