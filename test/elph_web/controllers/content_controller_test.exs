# credo:disable-for-this-file Credo.Check.Design.TagFIXME
defmodule ElphWeb.ContentControllerTest do
  use ElphWeb.ConnCase

  alias Elph.Contents
  alias Elph.Contents.Content

  @create_attrs %{type: "markdown", markdown: "dummy", shared: "true", name: "something"}
  @update_attrs %{}
  @invalid_attrs %{shared: true}

  def fixture(:content) do
    {:ok, content} = Contents.persist_content(@create_attrs)
    content
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all contents", %{conn: conn} do
      conn = get(conn, Routes.content_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create content" do
    test "renders content when data is valid", %{conn: conn} do
      conn = post(conn, Routes.content_path(conn, :create), content: @create_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.content_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.content_path(conn, :create), content: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update content" do
    setup [:create_content]

    # FIXME:
    @tag :skip
    test "renders content when data is valid", %{conn: conn, content: %Content{id: id} = content} do
      conn = put(conn, Routes.content_path(conn, :update, content), content: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.content_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    # FIXME:
    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, content: content} do
      conn = put(conn, Routes.content_path(conn, :update, content), content: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete content" do
    setup [:create_content]

    # FIXME:
    @tag :skip
    test "deletes chosen content", %{conn: conn, content: content} do
      conn = delete(conn, Routes.content_path(conn, :delete, content))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.content_path(conn, :show, content))
      end
    end
  end

  defp create_content(_) do
    content = fixture(:content)
    {:ok, content: content}
  end
end
