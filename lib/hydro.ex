defmodule Hydro do
  @moduledoc """
  Helpers to administrate or oversee Oban Workers

  Or in other words, a series of functions to help you find
  worrisome Oban configuration that might need a visit to
  the Oban Hydro Sanatorium.

  https://en.wikipedia.org/wiki/Oban_Hydro
  """

  @doc """
  Find Oban Workers associated in the given queues
  """
  def workers_by_queues(queue, app) when is_binary(queue) or is_atom(queue) do
    queue
    |> List.wrap()
    |> workers_by_queues(app)
  end

  def workers_by_queues(queues, app) when is_list(queues) do
    target_queues = Enum.map(queues, &to_string/1)

    app
    |> find_oban_workers()
    |> Enum.group_by(
      fn {worker, _attributes} ->
        worker.__opts__()
        |> Keyword.get(:queue, :default)
        |> to_string()
      end,
      &elem(&1, 0)
    )
    |> Map.filter(fn {queue, _} -> queue in target_queues end)
  end

  @doc """
  Find Oban Workers with _custom period_ in their `unique` option

  The `unique` option is not always needed. So, I tend to review
  these worker definitions to see why are we using a custom period,
  when the recommended value, after checking that the unique
  feature is actually needed, for `period` is `:infinity`.

  See: https://hexdocs.pm/oban/scaling.html#uniqueness
  """
  def unique_workers_with_custom_period(app) do
    app
    |> find_oban_workers()
    |> Enum.flat_map(fn {worker, _attributes} ->
      unique = Keyword.get(worker.__opts__(), :unique)

      case unique && unique[:period] do
        :infinity -> []
        nil -> []
        period -> [{worker, period}]
      end
    end)
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
  end

  @doc """
  Find unique workers without the `keys` option

  As suggested in the Scaling Application guide, first make
  sure you actually need the unique jobs feature, and if you do,
  always set the `keys` option so that uniqueness isn't based on
  the full `args` or `meta`

  See: https://hexdocs.pm/oban/scaling.html#uniqueness
  """
  def unique_workers_without_keys_option(app) do
    app
    |> find_oban_workers()
    |> Enum.flat_map(fn {worker, _attributes} ->
      unique = Keyword.get(worker.__opts__(), :unique)
      if unique && unique[:keys] != [], do: [worker], else: []
    end)
  end

  @doc """
  Classify workers based on "Unique State Groups"

  This State Groups are available since Oban v2.20.0
  See: https://github.com/oban-bg/oban/releases/tag/v2.20.0

  If one or more workers don't fall in the following unique groups:
  `all`, `incomplete`, `scheduled`, or `successful`, you should do a
  deep review in your worker module definition. 
  """
  def workers_by_unique_state_groups(app) do
    all = MapSet.new(~w(available scheduled executing retryable completed cancelled discarded)a)
    successful = MapSet.new(~w(available scheduled executing retryable completed)a)
    incomplete = MapSet.new(~w(available scheduled executing retryable)a)
    scheduled = MapSet.new(~w(scheduled)a)

    app
    |> find_oban_workers()
    |> Enum.flat_map(fn {worker, _attributes} ->
      unique = Keyword.get(worker.__opts__(), :unique)

      case unique && unique[:states] do
        states when is_list(states) ->
          states = MapSet.new(states)

          states =
            cond do
              MapSet.equal?(states, all) -> :all
              MapSet.equal?(states, successful) -> :successful
              MapSet.equal?(states, incomplete) -> :incomplete
              MapSet.equal?(states, scheduled) -> :scheduled
              true -> states |> MapSet.to_list() |> Enum.sort()
            end

          [{worker, states}]

        _ ->
          []
      end
    end)
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
  end

  @doc """
  Find workers without function wrappers

  ## Options

  * `names` - specifies the name of the wrappers. Default: `["enqueue"]`
  """
  def workers_without_wrappers(app, opts \\ []) do
    wrapper_names =
      opts
      |> Keyword.get(:names, "enqueue")
      |> List.wrap()
      |> MapSet.new()

    app
    |> find_oban_workers()
    |> Enum.flat_map(fn {worker, attributes} ->
      function_names =
        attributes
        |> Keyword.fetch!(:functions)
        |> MapSet.new(&(&1 |> elem(0) |> Atom.to_string()))

      intersection = MapSet.intersection(wrapper_names, function_names)

      if MapSet.equal?(intersection, wrapper_names) do
        []
      else
        non_implemented =
          wrapper_names
          |> MapSet.difference(intersection)
          |> MapSet.to_list()

        [{worker, non_implemented}]
      end
    end)
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
  end

  @doc """
  List all the Oban Workers for the given BEAM directory
  """
  def find_oban_workers(dir) do
    ["_build", mix_env | _] = Path.split(dir)

    [
      dir,
      "_build/#{mix_env}/lib/oban_pro/ebin",
      "_build/#{mix_env}/lib/oban/ebin"
    ]
    |> Enum.filter(&File.exists?/1)
    |> Code.prepend_paths()

    "*.beam"
    |> Path.expand(dir)
    |> Path.wildcard()
    |> Enum.map(&(&1 |> Path.basename(".beam") |> String.to_atom()))
    |> Enum.flat_map(fn module ->
      with {^module, binary, _file} <- :code.get_object_code(module),
           {:ok, {^module, chunk_data}} <- :beam_lib.chunks(binary, [:attributes, :exports]),
           true <-
             chunk_data
             |> get_in([:attributes, :behaviour])
             |> List.wrap()
             |> Enum.any?(&(&1 == Oban.Worker)) do
        [{module, functions: Keyword.fetch!(chunk_data, :exports)}]
      else
        _ -> []
      end
    end)
  end
end
