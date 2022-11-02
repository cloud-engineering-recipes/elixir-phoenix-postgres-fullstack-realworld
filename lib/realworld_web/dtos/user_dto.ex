defmodule RealWorldWeb.Dtos.UserDto do
  @moduledoc """
  The User DTO.
  """

  @derive Jason.Encoder
  defstruct [:email, :username, :token, :bio, :image]
end
