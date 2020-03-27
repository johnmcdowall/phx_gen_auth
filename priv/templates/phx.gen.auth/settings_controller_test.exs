defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>SettingsControllerTest do
  use <%= inspect context.web_module %>.ConnCase

  alias <%= inspect context.module %>
  import <%= inspect context.module %>Fixtures

  setup :register_and_login_<%= schema.singular %>

  describe "GET /<%= schema.plural %>/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if <%= schema.singular %> is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :edit))
      assert redirected_to(conn) == "/<%= schema.plural %>/login"
    end
  end

  describe "PUT /<%= schema.plural %>/settings/update_password" do
    test "updates the <%= schema.singular %> password and resets tokens", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      new_password_conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update_password), %{
          "current_password" => valid_<%= schema.singular %>_password(),
          "<%= schema.singular %>" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == "/<%= schema.plural %>/settings"
      assert get_session(new_password_conn, :<%= schema.singular %>_token) != get_session(conn, :<%= schema.singular %>_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email_and_password(<%= schema.singular %>.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update_password), %{
          "current_password" => "invalid",
          "<%= schema.singular %>" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match confirmation"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :<%= schema.singular %>_token) == get_session(conn, :<%= schema.singular %>_token)
    end
  end

  describe "PUT /<%= schema.plural %>/settings/update_email" do
    @tag :capture_log
    test "updates the <%= schema.singular %> email", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update_email), %{
          "current_password" => valid_<%= schema.singular %>_password(),
          "<%= schema.singular %>" => %{"email" => unique_<%= schema.singular %>_email()}
        })

      assert redirected_to(conn) == "/<%= schema.plural %>/settings"
      assert get_flash(conn, :info) =~ "A link to confirm your e-mail"
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(<%= schema.singular %>.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update_email), %{
          "current_password" => "invalid",
          "<%= schema.singular %>" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /<%= schema.plural %>/settings/confirm_email/:token" do
    setup %{<%= schema.singular %>: <%= schema.singular %>} do
      email = unique_<%= schema.singular %>_email()

      token =
        capture_<%= schema.singular %>_token(fn url ->
          <%= inspect context.alias %>.deliver_update_email_instructions(%{<%= schema.singular %> | email: email}, <%= schema.singular %>.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the <%= schema.singular %> email once", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>, token: token, email: email} do
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == "/<%= schema.plural %>/settings"
      assert get_flash(conn, :info) =~ "E-mail changed successfully"
      refute <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(<%= schema.singular %>.email)
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(email)

      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == "/<%= schema.plural %>/settings"
      assert get_flash(conn, :error) =~ "Email change token is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == "/<%= schema.plural %>/settings"
      assert get_flash(conn, :error) =~ "Email change token is invalid or it has expired"
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(<%= schema.singular %>.email)
    end

    test "redirects if <%= schema.singular %> is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == "/<%= schema.plural %>/login"
    end
  end
end
