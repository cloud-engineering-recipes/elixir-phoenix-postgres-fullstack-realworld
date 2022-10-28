defmodule RealWorldWeb.ChangesetView do
  use RealWorldWeb, :view

  @doc """
  Traverses and translates changeset errors.

  See `Ecto.Changeset.traverse_errors/2` and
  `RealWorldWeb.ErrorHelpers.translate_error/1` for more details.
  """
  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  def render("error.json", %{changeset: changeset}) do
    body =
      for {field, errors} <- translate_errors(changeset) do
        for error <- errors do
          "#{field} #{error}"
        end
      end
      |> List.flatten()

    %{errors: %{body: body}}
  end
end
