defmodule Elph.Contents.Callbacks do
  @moduledoc """
  In this file macros regarding custom callbacks are defined.

  To use custom callbacks this module has to be `use`d. Add `elph_cleanup_callbacks()` to use the
  default elph callbacks.

  Now you can add one or more callbacks. For example `cleanup_callback(&IO.inspect/1)`
  Each callback will be called with a list of explicitly deleted and garbage-colledted content
  (without its children, as from `Contents.list_contents`). So the above example would print a
  list of the deleted contents on your console.

  If you want to rerun the cleanup after all callbacks were run, return `:cleanup` in your function.
  Every other return will be ignored. Care not to produce infinity loops!

  The `use`ing file also has to be added to your config, to activate your callbacks:
  `config :elph, callbacks: <YourApp>.Callbacks`
  """
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :cleanup_callbacks, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def cleanup_callbacks do
        @cleanup_callbacks
      end
    end
  end

  defmacro elph_cleanup_callbacks do
    quote do
    end
  end

  defmacro cleanup_callback(callback) do
    quote do
      @cleanup_callbacks unquote(callback)
    end
  end
end

defmodule Elph.Contents.DefaultCallbacks do
  @moduledoc """
  The default elph callbacks. This will be automatically used if not defined otherwise
  in your config. See `Elph.Contents.Callbacks` for more info
  """
  use Elph.Contents.Callbacks

  elph_cleanup_callbacks()
end
