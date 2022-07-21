# Elph

Elph is a modular and easily customizable content management library that gives you pretty much everything you need for your basic phoenix project in terms of content-management.

It offers you easy content-management and a media library.

Just plug it into your existing phoenix app, add some configs, run migrations and you're ready to go.

> **_NOTE:_** For the time being elph has no authentication//authorization integrated. This will be added in the future, probably as a plug-in module.


## Prerequisites
- Elph needs [ffmpeg](https://ffmpeg.org/) to be installed to automatically convert uploaded media-files to browser-friendlier formats. This includes creating thumbnails for images and videos as well as transcoding videos and audio to mp4/mp3.

## Usage

- Add `{:elph, "~> 0.9.0}` to your `mix.exs` under `deps`
- Run `mix deps.get` to fetch it.
- Add the following to your `config.exs`
```
config :elph,
  repo: <YourApp>.Repo
  upload_dir: "/app/uploads/"
  url_upload_dir: "/uploads"
```
- Add the following to your `<YourAppWeb>Endpoint`
  - After your first `plug Plug.Static`-Block
```
plug Elph.UploadPlug
```
  - - In your `plug Plug.Parsers`-Block append a length attribute. For example `length: 100 * 1024 * 1024`  if you want to have a max upload size of 100MB.
- Add the following supervisor to your `<YourApp>.Application` in the `chilren` list in the `start/1` function
```
{Elph.MediaProcessing.BackgroundConverter, name: Elph.MediaProcessing.BackgroundConverter}
```
- Copy the migrations from `deps/elph/priv/repo/migrations` to `priv/repo/migrations` and run them with `mix ecto.create`


#### <YourAppWeb>.Router
To have the most control over everything you can use elph's contexts and controllers and need to do the routing yourself. 

- Add a scope using `ElphWeb` as ControllerScope and add the Routes using the respective Contollers.
  - Example:
    ```
    scope "/api", ElphWeb do
      pipe_through :api
      resources "/contents", ContentController, only: [:index, :show, :create, :delete]
      resources "/media", MediaController, only: [:create]
    end
    ```
- Make sure to split those routes and guard them with an authorization mechanism as needed.

#### FallbackController
Elph has a default phoenix FallbackController to show errors and such. If you want to use your own customized FallbackController add the following to `config.exs`: `config :elph, fallback_controller: <YourAppWeb>.FallbackController`

### Custom Types
Elph brings with it a list of default types. Those can be found in `elph/contents/types`. Those are included and available by default without more configuration.

In case this is not enough, you'll need to setup the use of custom types once and adding new types after that is pretty easy.
#### Setup
First we need to create the central point where we define our custom types.
- Create a new module like so
```
defmodule <YourApp>.Contents.Types do
  use Elph.Contents.Types

  elph_types()
end
```
- Add this module to the `config.exs`
```
config :elph, types: <YourApp>.Contents.Types
```
In this file you'll later add your types. In case you don't want to add all `elph_types()` you can use `only: [:html, :audio]` or `except: [:html, :audio]` to refine your choice.

#### Adding Types
Start off with a new schema created by `mix phx.gen.schema`.
For example: `mix phx.gen.schema Contents.Types.Markdown markdown_contents markdown:text`
- Hint: As a convention all Elph content types use `<type>_contents` as their schema source.

Now we need to change some stuff in the `<YourApp>.Contents.Types.Markdown` module.
- Add `use Ecto.Contents.ContentType` below `use Ecto.Schema`.
- Change `schema "markdown_contents" do` to `content_schema "markdown_contents" do`.
- Remove the `timestamps()` call in your schema as Elph already manages timestamps.
- Write your `changeset` as you would usually and only care about your own stuff. Don't embed or cast content-variables or child-contents. This will be handled automatically.
  - Care! The function has to be called `changeset` so it can be called by Elph
- If you need associated data to be preloaded automatically you can add `preloads(action)` to your module. This will be passed to `Ecto.Repo.preload` after your contents have been fetched from the database. **Beware**: If you have associated elph *contents*, you don't get whole contents. You'll only get the content type specific data, not the general information (`type`,`name` and `shared`) or the contents' children. This means you can't use the default elph `render` for those contents. If you need all the fields or even children use `content_preloads` (see below). Using `preloads` is faster and you should use it even for *contents*, if you don't need all fields.
- If you need all *contents* fields or even a whole subtree use `content_preloads(action)`. Beware: This works a little different then `Ecto.Repo.preload`.
  - You can only preload `:atom` or `[:atom1, :atom2]`. The other `preload` syntaxes are not supported. Nested preloads aren't either.
  - While loading the contents their `preloads` and `content_preloads` functions will also be loaded. Take care not to create cycles! (In case you do `elph` will have a fallback limiting the recursion depth to `3` so you don't end in an infinity loop. This can be changed via config option `content_preloads_max_depth` if your data structs are nested deeper then this)
  - As with `Ecto.Repo.preload` this will also not preload associations that are already loaded. So make sure not to include your association in both `preloads(_)` and `content_preloads(_)`.


Add your new type in your central content definition module (See paragraph above).
- `type(:markdown, <YourApp>.<YourContext>.Markdown, <YourAppWeb>.MarkdownView)` with the following params
  - The `name` of your type
  - The newly created module `<YourApp>.<YourContext>.MarkdownContent`
  - The view which will be called to render the result.
    - It needs a `def render("markdown.json", %{content: content}) do` function.
      - You can use `%{content: content, action: action}` instead, if you need to do rendering depending on this information.
      - Defaults are `:index` and `:show`.
    - Care! Use `<name>.json` as first param.

We also need to alter the created migration.
- Add `use Elph.Migration` below `use Ecto.Migration`
- In the `create table` call add `add_content_field()` and remove the `timestamps()`.


#### Cleanup
If you need your custom types to be cleaned up after them, you can add one or more callbacks.

##### Per Content-Type (preferred)
Add a `def after_delete_callback(content) do` to your custom content type module. This callback will be called
once for each (explicitly or via garbage collection) deleted content with the deleted content as parameter.
If you need the cleanup to re-run afterwards return `:cleanup`. All other returns are ignored.


##### Global (Not preferred)

As with custom types you'll first need to create a module:
```
defmodule <YourApp>.Callbacks do
  use Elph.Contents.Callbacks

  elph_cleanup_callbacks()
end
```

Now you can add one or more callbacks; for example `cleanup_callback(&IO.inspect/1)`

Each callback will be called with a list of explicitly deleted and garbage-colledted content (without its children, as one would get from `Contents.list_contents`). So the above example would print a list of the deleted contents on your console.

If you want to rerun the cleanup after all callbacks were run, return `:cleanup` in your function. Every other return will be ignored. Care not to produce infinity loops!

## Development
For the development of elph we created a project called [Elph-Shell](https://github.com/naymspace/elph-shell). It provides an api with some basic functionality. It also has some configuration set to make developing elph a little easier.

## Testing
To test elph you'll need a database. Per default Elph uses a mysql Database and reads the `DATABASE_URL` environment variable to aquire credentials.
In case you don't want to use MySql or a `DATABASE_URL` you can change your `config.ex` file. Additionally you'll need to change the adapter in `Elph.Test.Repo` and import your dependancy via `mix`.

### Preparations
To run tests from within elph-shell you need to create a new database for testing, since using the development database will give you errors.
For that open a shell to the docker-container
- `docker-compose enter phoenix bash`
Login to mysql as root
- `mysql -hdb -uroot -pmysql`
Create a database and give `mysql` all permissions
- `CREATE DATABASE elph_test;`
- `GRANT ALL PRIVILEGES ON elph_test.* TO 'mysql'@'%';`

### Running
To run your test simply change to the elph folder in case you're in the shell-directory with `cd elph`. For the first time - and after changing your migrations - you'll have to run `DATABASE_URL=mysql://mysql:mysql@db/elph_test MIX_ENV=test mix ecto.reset`.

After that you can run `DATABASE_URL=mysql://mysql:mysql@db/elph_test mix test` and everything should work out. If you want to see test-coverage you can add the parameter `--cover` to the command and elixir will show you a coverage percentage and put detailed reports into the cover-subdirectory.