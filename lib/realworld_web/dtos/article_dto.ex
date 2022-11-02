defmodule RealWorldWeb.Dtos.ArticleDto do
  @moduledoc """
  The Article DTO.
  """

  @derive Jason.Encoder
  defstruct [
    :slug,
    :title,
    :description,
    :body,
    :tagList,
    :createdAt,
    :updatedAt,
    :favorited,
    :favoritesCount,
    :author
  ]
end
