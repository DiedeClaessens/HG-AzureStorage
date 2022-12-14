defmodule AzureStorage.Table.QueryBuilder do
  @moduledoc """
  Azure Table Storage Query Builder
  """
  alias AzureStorage.Table.Query

  @comparition [
    :eq,
    :ne,
    :le,
    :ge,
    :lt,
    :le
  ]

  @spec where(Query.t(), String.t()) :: Query.t()
  def where(%Query{} = query, criteria) when is_bitstring(criteria) do
    add_filter(query, :and, criteria)
  end

  @spec where(Query.t(), String.t(), atom(), any()) :: Query.t()
  def where(%Query{} = query, field, comparition, value)
      when comparition in @comparition do
    criteria = field(field, comparition, value)
    add_filter(query, :and, criteria)
  end

  @doc """
  Build or expression
  """
  @spec or_where(Query.t(), String.t()) :: Query.t()
  def or_where(%Query{} = query, criteria) when is_bitstring(criteria) do
    add_filter(query, :or, criteria)
  end

  @doc """
  Build or expression
  """
  def or_where(%Query{} = query, field, comparition, value)
      when comparition in @comparition do
    criteria = field(field, comparition, value)
    add_filter(query, :or, criteria)
  end

  @doc """
  Select top entities
  """
  @spec top(Query.t(), integer) :: Query.t()
  def top(%Query{} = query, count) do
    %{query | top: count}
  end

  @doc """
  Generate query path from `AzureStorage.Table.Query`
  """
  def compile(%Query{filter: filter, table: table, top: top}) do
    filter =
      filter
      |> Enum.reverse()
      |> Enum.join("%20")

    "#{table}?$filter=#{filter}&$top=#{top}"
  end

  defp add_filter(%Query{filter: filter} = query, connector, criteria)
       when is_bitstring(criteria) and
              connector in [:and, :or] do
    filter =
      case filter do
        nil -> ["(#{criteria})"]
        _ -> ["#{Atom.to_string(connector)}%20(#{criteria})" | filter]
      end

    %{query | filter: filter}
  end

  # ----------------------

  defp field(field, comparition, value)
       when comparition in @comparition do
    field_value = field_value(value)
    "#{field}%20#{Atom.to_string(comparition)}%20#{field_value}"
  end

  defp field_value(value) when is_number(value) or is_boolean(value), do: "#{value}"

  defp field_value(value) do
    cond do
      is_date?(value) -> "datetime'#{value}'"
      is_guid?(value) -> "guid'#{value}'"
      true -> "'#{value |> escape}'"
    end
  end

  defp is_guid?(value) do
    String.match?(value, ~r/^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/)
  end

  defp is_date?(date) do
    case date do
      %NaiveDateTime{} -> true
      %DateTime{} -> true
      _ -> false
    end
  end

  defp escape(value) do
    value |> URI.encode()
  end
end
