defmodule Elph.Contents.Types do
  @moduledoc """
  In this file the macros regarding custom types are defined.
  To use custom types this module has to be `use`d. Add `elph_types()` to use the default elph
  content types.
  For each type add `type(:markdown, <YourApp>.<YourContext>.Markdown, <YourAppWeb>.MarkdownView)`
  with the following params
  - The `name` of your type
  - Your content module `<YourApp>.<YourContext>.MarkdownContent`
  - The view which will be called to render the result.
    - It needs a `def render("markdown.json", %{content: content}) do` function.
    - Care! Use `<name>.json` as first param.
    - Alternatively you can use `nil` if you dont need to render any type-specific fields

  The `use`ing file also has to be added to your config, to activate your custom types:
  `config :elph, types: <YourApp>.Contents.Types`
  """
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :types, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @types_map Map.new(@types, fn {name, module, view} -> {name, {module, view}} end)

      def get_type(type) when is_binary(type) do
        type |> String.to_existing_atom() |> get_type()
      rescue
        ArgumentError -> nil
      end

      def get_type(type) when is_atom(type) do
        Map.get(@types_map, type)
      end

      def get_module(type) do
        with {module, _} <- get_type(type) do
          module
        end
      end

      def get_view(type) do
        with {_, view} <- get_type(type) do
          view
        end
      end

      def get_content_types do
        @types
      end

      def valid_type?(type) do
        get_type(type) !== nil
      end
    end
  end

  defmacro elph_types(opts \\ []) do
    all_types = ~w(markdown list accordion html image video audio)a
    only_types = Keyword.get(opts, :only, all_types)
    except_types = Keyword.get(opts, :except, [])
    types = Enum.reject(only_types, &Enum.member?(except_types, &1))

    [
      if Enum.member?(types, :markdown) do
        quote do
          markdown()
        end
      end,
      if Enum.member?(types, :list) do
        quote do
          list()
        end
      end,
      if Enum.member?(types, :accordion) do
        quote do
          accordion()
        end
      end,
      if Enum.member?(types, :html) do
        quote do
          html()
        end
      end,
      if Enum.member?(types, :image) do
        quote do
          image()
        end
      end,
      if Enum.member?(types, :video) do
        quote do
          video()
        end
      end,
      if Enum.member?(types, :audio) do
        quote do
          audio()
        end
      end
    ]
  end

  defmacro markdown do
    quote do
      type(:markdown, Elph.Contents.Types.Markdown, ElphWeb.ContentView)
    end
  end

  defmacro list do
    quote do
      type(:list, Elph.Contents.Types.ListContainer, nil)
    end
  end

  defmacro accordion do
    quote do
      type(:accordion, Elph.Contents.Types.AccordionContainer, ElphWeb.ContentView)
    end
  end

  defmacro html do
    quote do
      type(:html, Elph.Contents.Types.Html, ElphWeb.ContentView)
    end
  end

  defmacro image do
    quote do
      type(:image, Elph.Contents.Types.Image, ElphWeb.MediaView)
    end
  end

  defmacro video do
    quote do
      type(:video, Elph.Contents.Types.Video, ElphWeb.MediaView)
    end
  end

  defmacro audio do
    quote do
      type(:audio, Elph.Contents.Types.Audio, ElphWeb.MediaView)
    end
  end

  defmacro type(name, module, view) do
    quote do
      @types {unquote(name), unquote(module), unquote(view)}
    end
  end
end

defmodule Elph.Contents.DefaultTypes do
  @moduledoc """
  The default elph content types. This will be automatically used if not defined otherwise
  in your config. See `Elph.Contents.Types` for more info.
  """
  use Elph.Contents.Types

  elph_types()
end
