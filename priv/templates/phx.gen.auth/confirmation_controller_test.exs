defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>ConfirmationControllerTest do
  use <%= inspect context.web_module %>.ConnCase<%= test_case_options %>

  alias <%= inspect context.module %>
  alias <%= inspect schema.repo %>
  import <%= inspect context.module %>Fixtures

  setup do
    %{<%= schema.singular %>: <%= schema.singular %>_fixture()}
  end

  describe "GET /<%= schema.singular %>s/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.<%= schema.route_helper %>_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /<%= schema.singular %>s/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn =
        post(conn, Routes.<%= schema.route_helper %>_confirmation_path(conn, :create), %{
          "<%= schema.singular %>" => %{"email" => <%= schema.singular %>.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your e-mail is in our system"
      assert Repo.get_by!(<%= inspect context.alias %>.<%= inspect schema.alias %>Token, <%= schema.singular %>_id: <%= schema.singular %>.id).context == "confirm"
    end

    test "does not send confirmation token if account is confirmed", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      Repo.update!(<%= inspect context.alias %>.<%= inspect schema.alias %>.confirm_changeset(<%= schema.singular %>))

      conn =
        post(conn, Routes.<%= schema.route_helper %>_confirmation_path(conn, :create), %{
          "<%= schema.singular %>" => %{"email" => <%= schema.singular %>.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your e-mail is in our system"
      refute Repo.get_by(<%= inspect context.alias %>.<%= inspect schema.alias %>Token, <%= schema.singular %>_id: <%= schema.singular %>.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.<%= schema.route_helper %>_confirmation_path(conn, :create), %{
          "<%= schema.singular %>" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your e-mail is in our system"
      assert Repo.all(<%= inspect context.alias %>.<%= inspect schema.alias %>Token) == []
    end
  end

  describe "GET /<%= schema.singular %>s/confirm/:token" do
    test "confirms the given token once", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      token =
        extract_<%= schema.singular %>_token(fn url ->
          <%= inspect context.alias %>.deliver_<%= schema.singular %>_confirmation_instructions(<%= schema.singular %>, url)
        end)

      conn = get(conn, Routes.<%= schema.route_helper %>_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Account confirmed successfully"
      assert <%= inspect context.alias %>.get_<%= schema.singular %>!(<%= schema.singular %>.id).confirmed_at
      refute get_session(conn, :<%= schema.singular %>_token)
      assert Repo.all(<%= inspect context.alias %>.<%= inspect schema.alias %>Token) == []

      conn = get(conn, Routes.<%= schema.route_helper %>_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Confirmation link is invalid or it has expired"
    end

    test "does not confirm email with invalid token", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = get(conn, Routes.<%= schema.route_helper %>_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Confirmation link is invalid or it has expired"
      refute <%= inspect context.alias %>.get_<%= schema.singular %>!(<%= schema.singular %>.id).confirmed_at
    end
  end
end
