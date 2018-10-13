# Overview

Steve is an Elixir background job processor inspired by
[verk](https://github.com/edgurgel/verk) and
[exq](https://github.com/akira/exq).

### Structure

Steve is planned out to be simple and intuitive
both on its internals and when it comes to user
interaction. As such, its structure is rather
straightforward and compact, schemed across multiple
modules as follows.

- [Job](./Steve.Job.html) - defines useful helper
functions used when creating job structures.
- [Queue](./Steve.Queue.html) - serves as the brain
for each of the queues the library is subscribed to.
- Storage - different adapters to pick from to be
used for persisting the jobs.
- [Worker](./Steve.Worker.html) - defines a behaviour
to be implemented by all the job workers.

### Usage

Currently there is no package published on Hex and
instead one must include Steve as follows.

```elixir
defp deps do
  [{:steve, git: "https://github.com/satom99/steve.git"}]
end
```

Once installed, Steve must be configured according to the
desired storage adapter. One may find more information on
this on the adapter's documentation page.

Once these steps are completed, one may configure their
application to subscribe to the desired queues automatically.
This can be done by adding the following configuration parameter
to their application:

```elixir
config :steve, :queues,
[
  [name: :emails, size: 5],
  [name: :webhooks, size: 25]
]
```
Do note as well that these keyword lists are the options that the function
`Steve.Queue.create/1` takes in.
