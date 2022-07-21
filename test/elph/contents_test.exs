# credo:disable-for-this-file Credo.Check.Design.TagFIXME
defmodule Elph.ContentsTest do
  use Elph.DataCase

  alias Elph.Contents

  describe "contents" do
    @shared_keys ["type", "name", "shared"]

    @valid_markdown_content_unshared %{
      "type" => "markdown",
      "name" => "",
      "shared" => false,
      "markdown" => "some markdown"
    }

    @valid_markdown_content %{
      "type" => "markdown",
      "name" => "markdown",
      "shared" => true,
      "markdown" => "some other markdown"
    }

    @valid_html_content %{
      "type" => "html",
      "name" => "shared html",
      "shared" => true,
      "html" => "some html"
    }

    @valid_content_subtree_unshared %{
      "type" => "list",
      "name" => "",
      "shared" => false,
      "children" => [
        @valid_markdown_content
      ]
    }

    @valid_content_tree %{
      "type" => "list",
      "name" => "parent",
      "shared" => true,
      "children" => [
        @valid_content_subtree_unshared,
        @valid_markdown_content_unshared,
        @valid_html_content
      ]
    }

    @invalid_type %{
      "name" => "wrong_type",
      "type" => "doesnotexist",
      "shared" => true,
      "something" => "anything"
    }

    def content_fixture(attrs \\ %{}) do
      {:ok, content} =
        attrs
        |> Contents.persist_content()

      content
    end

    defp assert_equals_in_shared_attributes({content1, content2}, check_ids) do
      assert_equals_in_shared_attributes(content1, content2, check_ids)
    end

    defp assert_equals_in_shared_attributes(content1, content2, check_ids) do
      keys = if check_ids, do: ["id" | @shared_keys], else: @shared_keys

      transformed_content1 = transform_to_string_map(content1)
      transformed_content2 = transform_to_string_map(content2)
      assert Map.take(transformed_content1, keys) == Map.take(transformed_content2, keys)

      # credo:disable-for-lines:2
      Enum.zip(Map.get(content1, :children, []), Map.get(content2, :children, []))
      |> Enum.each(&assert_equals_in_shared_attributes(&1, check_ids))
    end

    defp transform_to_string_map(%_{} = content) do
      content |> Map.from_struct() |> transform_to_string_map()
    end

    defp transform_to_string_map(content) do
      reducer = fn
        {key, value}, acc ->
          transformed_key = if is_atom(key), do: Atom.to_string(key), else: key

          transformed_value =
            case transformed_key do
              "type" when is_atom(value) -> Atom.to_string(value)
              _ -> value
            end

          Map.put(acc, transformed_key, transformed_value)
      end

      Enum.reduce(content, %{}, reducer)
    end

    defp assert_has_id(content) do
      assert Map.get(content, "id") > 0
      Enum.map(Map.get(content, :children, []), &assert_has_id/1)
    end

    defp flatten_content_tree(content) do
      [
        Map.put(content, :children, nil)
        | Enum.flat_map(Map.get(content, :children, []), &flatten_content_tree/1)
      ]
    end

    test "persist_content/1 with valid tree creates a content tree" do
      content = content_fixture(@valid_content_tree)

      assert_equals_in_shared_attributes(content, @valid_content_tree, false)
      assert_has_id(content)
    end

    test "get_content!/1 returns the content tree with given id" do
      %{id: content_id} = content = content_fixture(@valid_content_tree)

      assert content == Contents.get_content!(content_id)
    end

    test "list_contents/1 returns all contents when show_all is true" do
      content = content_fixture(@valid_content_tree)

      good_contents = flatten_content_tree(content)

      assert good_contents == Contents.list_contents(show_all: true)
    end

    test "list_contents/1 returns only shared contents when show_all is not set or false" do
      content = content_fixture(@valid_content_tree)

      good_contents = content |> flatten_content_tree() |> Enum.filter(& &1.shared)

      assert good_contents == Contents.list_contents()
    end

    test "list_contents/1 returns all contents of specified types when show_all is true and a filter is set" do
      content = content_fixture(@valid_content_tree)

      good_contents =
        content
        |> flatten_content_tree()
        |> Enum.filter(&(&1.type == :markdown || &1.type == :html))

      assert good_contents == Contents.list_contents(show_all: true, type: [:markdown, :html])
    end

    test "list_contents/1 returns only shared contents of types when show_all is false and a filter is set" do
      content = content_fixture(@valid_content_tree)

      good_contents =
        content
        |> flatten_content_tree()
        |> Enum.filter(& &1.shared)
        |> Enum.filter(&(&1.type == :markdown || &1.type == :html))

      assert good_contents == Contents.list_contents(show_all: false, type: [:markdown, :html])
    end

    test "persist_content/1 can not change type of existing node but returns error changeset" do
      %{id: content_id} = content_fixture(@valid_markdown_content)

      updated_attrs =
        Map.merge(@valid_markdown_content, %{
          "type" => "html",
          "html" => "some html",
          "id" => content_id
        })

      # FIXME: This should not be a raise, but that's what we get right now
      assert_raise Ecto.NoResultsError, fn -> Contents.persist_content(updated_attrs) end
    end

    test "persist_content/1 with invalid type returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.persist_content(@invalid_type)
    end

    test "persist_content/1 creating non-shared root-node returns error changeset" do
      # FIXME: This should not be a raise, but that's what we get right now
      assert_raise(Ecto.NoResultsError, fn ->
        Contents.persist_content(@valid_markdown_content_unshared)
      end)
    end

    test "persist_content/1 with valid data updates the content, when id is set" do
      %{id: content_id} = content_fixture(@valid_html_content)
      new_html = "some new html"

      updated_attrs =
        Map.merge(@valid_html_content, %{
          "html" => new_html,
          "id" => content_id,
          "name" => "new html"
        })

      {:ok, updated_content} = Contents.persist_content(updated_attrs)

      assert updated_content.html == new_html
      assert_equals_in_shared_attributes(updated_attrs, updated_content, true)
    end

    test "persist_content/1 with valid data updates contents, where their id is set and creates new otherwise" do
      %{
        id: root_id,
        children: [
          %{
            id: subtree_id,
            children: [
              %{id: subtree_markdown_id}
            ]
          },
          %{id: markdown_id},
          %{id: html_id}
        ]
      } = content_fixture(@valid_content_tree)

      updated_attrs =
        Map.merge(@valid_content_tree, %{
          "id" => root_id,
          "children" => [
            @valid_markdown_content,
            Map.merge(@valid_markdown_content_unshared, %{"id" => markdown_id}),
            Map.merge(@valid_html_content, %{"id" => html_id})
          ]
        })

      {:ok,
       %{
         id: updated_root_id,
         children: [
           %{id: new_markdown_id},
           %{id: updated_markdown_id},
           %{id: updated_html_id}
         ]
       } = updated_content} = Contents.persist_content(updated_attrs)

      assert_equals_in_shared_attributes(updated_attrs, updated_content, false)
      assert new_markdown_id != subtree_id
      assert new_markdown_id != subtree_markdown_id
      assert markdown_id == updated_markdown_id
      assert html_id == updated_html_id
      assert root_id == updated_root_id
    end

    test "persist_content/1 can update subtree without detaching it from existing parents" do
      %{
        id: root_id,
        children: [
          %{
            id: subtree_id,
            children: [
              %{id: subtree_markdown_id}
            ]
          },
          %{},
          %{}
        ]
      } = content = content_fixture(@valid_content_tree)

      updated_attrs =
        Map.merge(@valid_content_subtree_unshared, %{
          "id" => subtree_id,
          "children" => [
            Map.merge(@valid_markdown_content, %{
              "id" => subtree_markdown_id,
              "markdown" => "some updated markdown"
            })
          ]
        })

      Contents.persist_content(updated_attrs)

      updated_root_tree = Contents.get_content!(root_id)

      assert_equals_in_shared_attributes(content, updated_root_tree, true)
    end

    test "persist_content/1 can attach subtree to another parent while it stays attached to the first" do
      %{
        id: root_id,
        children: [
          %{
            id: subtree_id,
            children: [
              %{id: subtree_markdown_id}
            ]
          },
          %{},
          %{}
        ]
      } = content = content_fixture(@valid_content_tree)

      updated_attrs = %{
        "type" => "list",
        "name" => "new parent",
        "shared" => true,
        "children" => [
          Map.merge(@valid_content_subtree_unshared, %{
            "id" => subtree_id,
            "children" => [
              Map.merge(@valid_markdown_content, %{
                "id" => subtree_markdown_id,
                "markdown" => "some updated markdown"
              })
            ]
          })
        ]
      }

      Contents.persist_content(updated_attrs)

      updated_root_tree = Contents.get_content!(root_id)

      assert_equals_in_shared_attributes(content, updated_root_tree, true)
    end

    test "persist_content/1 can move a branch from one parent to another" do
      %{
        id: root_id,
        children: [
          %{
            id: subtree_id,
            children: [
              %{id: subtree_markdown_id}
            ]
          },
          %{id: markdown_id},
          %{id: html_id}
        ]
      } = content_fixture(@valid_content_tree)

      update_attrs =
        Map.merge(@valid_content_tree, %{
          "id" => root_id,
          "children" => [
            Map.merge(@valid_content_subtree_unshared, %{"id" => subtree_id, "children" => []}),
            Map.merge(@valid_markdown_content, %{"id" => subtree_markdown_id}),
            Map.merge(@valid_markdown_content_unshared, %{"id" => markdown_id}),
            Map.merge(@valid_html_content, %{"id" => html_id})
          ]
        })

      {:ok, updated_contents} = Contents.persist_content(update_attrs)

      assert_equals_in_shared_attributes(update_attrs, updated_contents, true)
    end

    test "persist_content/1 can orphan a branch and delete it automatically when it is not referenced anymore" do
      %{
        id: root_id,
        children: [
          %{},
          %{id: markdown_id},
          %{}
        ]
      } = content_fixture(@valid_content_tree)

      update_attrs =
        Map.merge(@valid_content_tree, %{
          "id" => root_id,
          "children" => []
        })

      Contents.persist_content(update_attrs)

      assert_raise(Ecto.NoResultsError, fn -> Contents.get_content!(markdown_id) end)
    end

    test "persist_content/1 can detach a branch but not delete it, when it is shared or referenced otherwise" do
      %{
        id: root_id,
        children: [
          %{},
          %{},
          %{id: html_id}
        ]
      } = content_fixture(@valid_content_tree)

      update_attrs =
        Map.merge(@valid_content_tree, %{
          "id" => root_id,
          "children" => []
        })

      Contents.persist_content(update_attrs)

      not_deleted_content = Contents.get_content!(html_id)

      assert_equals_in_shared_attributes(not_deleted_content, @valid_html_content, false)
    end

    @tag :skip
    test "list_contents/1 returns current_page and pages_count when page_size is set"

    @tag :skip
    test "list_contents/1 returns first n items when page_size is set to n and page is not set"

    @tag :skip
    test "list_contents/1 returns mth n items when page_size is set to n and page is set to m"

    @tag :skip
    test "list_contents/1 returns an empty list when page_size is set and page > max_pages"

    @tag :skip
    test "list_contents/1 returns only contents of which their names include the search-phrase"

    @tag :skip
    test "delete_content/1 deletes the content"

    @tag :skip
    test "delete_content/1 deletes the content and its orphaned children get cleaned up"

    @tag :skip
    test "persist_content/1 with a new media-content returns error changeset"

    @tag :skip
    test "create_media_content/1 creates a new file on disk and an content with it"

    @tag :skip
    test "create_media_content/1 with invalid data returns error changeset (and saves no file on disk)"

    @tag :skip
    test "persist_content/1 deletes orphaned media content and associated file"

    @tag :skip
    test "delete_content/1 deletes media content with associated file"
  end
end
