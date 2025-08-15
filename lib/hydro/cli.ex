defmodule Hydro.CLI do
  @moduledoc """
  CLI interface for Hydro
  """
  @version Hydro.MixProject.project()[:version]

  @aliases [
    h: :help,
    v: :version,
    q: :queue,
    p: :prefix
  ]

  @switches [
    help: :boolean,
    version: :boolean,
    queue: :keep,
    prefix: :keep
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
        [command, app] = args
        process(command, app, opts)

      true ->
        print_usage()
    end
  end

  defp process(command, app, opts) when command in @valid_commands do
    case validate_application(app) do
      {:ok, app} ->
        command = String.to_existing_atom(command)
        process(command, app, opts)

      :error ->
        raise ArgumentError, "cannot find the application #{inspect(app)}"
    end
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
    prefixes = Keyword.get_values(opts, :prefix)
    wrapper_names = (prefixes == [] && ["enqueue"]) || prefixes

    app
    |> Hydro.workers_without_wrappers(prefixes: wrapper_names)
    |> Enum.map(&(&1 |> inspect() |> IO.puts()))
  end

  defp process(_, _, _) do
    message = "Invalid arguments"
    message_formatted = IO.ANSI.format([:red, message, :reset])
    IO.puts(message_formatted)
    print_usage()
  end

  defp validate_application(maybe_app) do
    found? =
      Enum.find(
        Application.loaded_applications(),
        fn {app, _, _} ->
          maybe_app == to_string(app)
        end
      )

    if found?, do: {:ok, String.to_existing_atom(maybe_app)}, else: :error
  end

  defp print_version, do: IO.puts("Hydro v#{@version}")

  defp print_usage do
    IO.puts("""
    Usage:
      hydro command app [OPTIONS]

    Examples:
      hydro workers_by_queues app -q email --queue default
      hydro workers_without_wrappers app -p enqueue --prefix prepare
      hydro unique_workers_with_custom_period app
      hydro unique_workers_without_keys_option app
      hydro workers_by_unique_state_groups app

    Options:
      -v, --version Prints the Hydro version.
      -h, --help    Print this usage.
      -q, --queue   Specifies one or multiple Oban queues
      -p, --prefix  Indicates one or multiple Oban wrapper prefixes
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
