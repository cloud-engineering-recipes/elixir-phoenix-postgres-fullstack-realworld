defmodule RealWorldWeb.ErrorView do
  use RealWorldWeb, :view

  def render("401.json", _assigns) do
    %{errors: %{body: ["unauthorized"]}}
  end

  def render("changeset.json", %{changeset: changeset}) do
    body =
      for {field, errors} <- translate_errors(changeset) do
        for error <- errors do
          "#{field} #{error}"
        end
      end
      |> List.flatten()

    %{errors: %{body: body}}
  end

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
