# Hydro

Hydro include conveniences for developers that oversees Oban Workers
and want to find areas to improve.

## Installation

```console
mix escript.install github milmazz/hydro
```

## Usage

```console
hydro --help
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
```

## Commands

* [Workers by unique state groups](#workers-by-unique-state-groups)
* [Unique Workers without keys option](#unique-workers-without-keys-option)
* [Unique Workers with custom period](#unique-workers-with-custom-period)
* [Workers by queues](#workers-by-queues)
* [Workers without wrappers](#workers-without-wrappers)

### Workers by unique state groups

This command is useful to find Oban Workers`` by _Unique States Group_
(e.g., `:all`, `:incomplete`, `scheduled`, `:successful`), which were
introduced with Oban [v2.20.0][]. So, you can update your Oban Worker definition
to use the group instead.

This command also display cases that don't satisfy the _Unique States Group_,
for example: `[:scheduled, :available, :executing]` can create unexpected
race conditions because the missing `:retryable` state.

EXAMPLE

### Unique Workers without keys option

As stated in the [Scaling Applications][] guide, _after_ verifying that you
actually require the _unique_ feature, you always have to specify the
`keys` option under the `unique`, this is mainly to avoid using the
whole `args` or `meta`.

EXAMPLE

### Unique Workers with custom period

In the same vein as the previous command, once you have verified you actually require
the _unique_ feature, the [Scaling Applications] guide recommends to replace custom
periods of time with the value `:infinity`, this commands help you finding those
offending Oban Worker definitions and groups them by their period value:

EXAMPLE

### Workers by queues

If you need to filter Oban Workers by one or more queues, this command will do the
work for you.

EXAMPLE

### Workers without wrappers

As suggested in my post about [Oban: job processing library for Elixir][], I
prefer to keep calls to `Oban.insert` or `Oban.insert_all` contained in my workers.

Following this approach, you also avoid polluting your controllers, resolvers, or
contexts with a sequence of calls like the following:

```elixir
my_job_args
|> MyApp.MyWorker.new()
|> Oban.insert()
```

In multiple places, so, I usually prefer to create small function wrappers in the
Worker module like:

```elixir
defmodule MyApp.MyWorker do
  use Oban.Worker

  def enqueue(thing_id) do
    %{thing_id: thing_id}
    |> MyApp.EmailDeliver.new()
    |> Oban.insert()
  end
end
```

Remember that your enqueue function doesn't need to have an arity of one; adjust
the number of arguments depending on what your worker expects.

With this command you can track which worker haven't implemented one or more wrappers.

EXAMPLE

[Scaling Applications]: https://hexdocs.pm/oban/scaling.html#uniqueness
[v2.20.0]: https://github.com/oban-bg/oban/releases/tag/v2.20.0
[Oban: job processing library for Elixir]: https://milmazz.uno/article/2022/02/11/oban-job-processing-package-for-elixir/
