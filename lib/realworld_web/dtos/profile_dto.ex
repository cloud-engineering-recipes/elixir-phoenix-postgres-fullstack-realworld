defmodule RealWorldWeb.Dtos.ProfileDto do
  @moduledoc """
  The Profile DTO.
  """

  @derive Jason.Encoder
  defstruct [:username, :bio, :image, :following]
end
