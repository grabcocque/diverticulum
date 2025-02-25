defmodule NetMancer do
  @moduledoc """
  Interaction net evaluator with Mermaid visualization.
  Structure thy code as the three weird sisters structure fate!
  """

  defstruct agents: %{}, connections: %{}, counter: 0

  @type agent :: %{
          id: pos_integer,
          type: :value | :function,
          ports: list(pos_integer),
          data: any
        }

  @doc """
  Initialize net with base elements - much like BBC BASIC's
  ```10 CLS
  20 PRINT "INIT"```
  """
  def new_net, do: %NetMancer{}

  @doc """
  Spawn new agent in the net. Choose form carefully:
  - For values: `conjure_agent(net, :value, 1, data)`
  - For functions: `conjure_agent(net, :function, 2, {:lambda, fn x -> x * 2 end})`
  """
  # Modify conjure_agent to accept name/data pattern
  def conjure_agent(%NetMancer{} = net, :value, port_count, data) do
    id = net.counter + 1

    %{
      net
      | agents:
          Map.put(net.agents, id, %{
            id: id,
            type: :value,
            ports: 1..port_count |> Enum.to_list(),
            data: data
          }),
        counter: id
    }
  end

  def conjure_agent(%NetMancer{} = net, :function, port_count, {op_name, func}) do
    id = net.counter + 1

    %{
      net
      | agents:
          Map.put(net.agents, id, %{
            id: id,
            type: :function,
            ports: 1..port_count |> Enum.to_list(),
            data: {op_name, func}
          }),
        counter: id
    }
  end

  @doc """
  Connect ports with arcane bonds. Syntax:
  `forge_connection(net, {agent1_id, port_num}, {agent2_id, port_num})`
  """
  def forge_connection(net, from, to) do
    %{net | connections: Map.put(net.connections, from, to)}
  end

  @doc """
  Performs a complete evaluation of the net until no more reductions can occur.
  """
  def evaluate(net) do
    {reduced_net, charts} = reduce_until_normal(net, [])
    {reduced_net, charts}
  end

  defp reduce_until_normal(net, charts) do
    case try_apply_rule(net) do
      {:apply, new_net} ->
        charts = charts ++ [mermaid_incantation(new_net)]
        IO.puts("Applied reduction rule!")
        reduce_until_normal(new_net, charts)

      {:expand, new_net} ->
        charts = charts ++ [mermaid_incantation(new_net)]
        IO.puts("Applied expansion rule!")
        reduce_until_normal(new_net, charts)

      :no_rule ->
        {net, charts}
    end
  end

  defp try_apply_rule(net) do
    # Find the first active pair
    case find_active_pair(net) do
      nil ->
        :no_rule

      {function_id, value_id} ->
        # Extraction and application logic stays the same
        function_agent = Map.get(net.agents, function_id)
        value_agent = Map.get(net.agents, value_id)

        # Extract function and value
        {_, func} = function_agent.data
        value_data = value_agent.data

        # Apply the function
        result = func.(value_data)

        # Create a new value agent with the result
        new_id = net.counter + 1
        result_agent = %{id: new_id, type: :value, ports: [1], data: result}

        # Handle outgoing connections
        new_net = %{
          net
          | counter: new_id,
            agents:
              Map.put(
                Map.drop(net.agents, [function_id, value_id]),
                new_id,
                result_agent
              )
        }

        # Handle any remaining connections by reconnecting them to result
        new_connections =
          reconnect_ports(
            net.connections,
            function_id,
            value_id,
            new_id
          )

        {:apply, %{new_net | connections: new_connections}}

      {nil, nil} ->
        # No active pair found
        :no_rule

      # unreachable
      _ ->
        :no_rule
    end
  end

  defp find_active_pair(net) do
    # Use Enum.reduce_while to find the first matching active pair
    Enum.reduce_while(net.connections, nil, fn
      # Check each connection
      {{id1, port1}, {id2, port2}}, _acc ->
        # Only consider connections between principal ports
        if port1 == 1 && port2 == 1 do
          agent1 = Map.get(net.agents, id1)
          agent2 = Map.get(net.agents, id2)

          # Check various combinations of function/value pairs
          cond do
            agent1.type == :function && agent2.type == :value ->
              {:halt, {id1, id2}}

            agent2.type == :function && agent1.type == :value ->
              {:halt, {id2, id1}}

            true ->
              {:cont, nil}
          end
        else
          {:cont, nil}
        end
    end)
  end

  defp reconnect_ports(connections, function_id, value_id, new_id) do
    # First, filter out connections directly between the eliminated agents
    remaining_connections =
      connections
      |> Enum.reject(fn {{f_id, _}, {t_id, _}} ->
        (f_id == function_id && t_id == value_id) ||
          (f_id == value_id && t_id == function_id)
      end)

    # Now replace references to eliminated agents with the new result agent
    new_connections =
      remaining_connections
      |> Enum.map(fn {from, to} ->
        {from_id, from_port} = from
        {to_id, to_port} = to

        cond do
          # For connections FROM eliminated agents to other agents:
          # If it's the principal port, drop it (already consumed)
          # If it's an auxiliary port, rewire to result agent
          from_id == function_id && from_port > 1 ->
            # Rewire to result's principal port
            {{new_id, 1}, to}

          from_id == value_id && from_port > 1 ->
            # Rewire to result's principal port
            {{new_id, 1}, to}

          # For connections TO eliminated agents from other agents
          to_id == function_id && to_port > 1 ->
            # Rewire to result's principal port
            {from, {new_id, 1}}

          to_id == value_id && to_port > 1 ->
            # Rewire to result's principal port
            {from, {new_id, 1}}

          # Keep other connections unchanged
          true ->
            {from, to}
        end
      end)
      # Convert back to a map
      |> Map.new()

    new_connections
  end

  def mermaid_incantation(net) do
    """
    ```mermaid
    graph LR
      #{Enum.map_join(net.agents, "\n      ", &render_agent/1)}

      #{Enum.map_join(net.connections, "\n      ", &render_connection/1)}
    ```
    """
  end

  defp render_agent({id, agent}) do
    # By convention
    principal_port = 1

    name =
      case agent do
        %{type: :value} -> "N#{agent.data}"
        %{type: :function, data: {op_name, _}} -> "#{op_name}"
        _ -> "Agent#{id}"
      end

    # Fixed: Each element properly quoted, line breaks handled correctly
    "#{id}[\"#{agent.type} #{id}<br/>#{name}<br/>P#{principal_port}\"]"
  end

  defp render_connection({{from_id, from_port}, {to_id, to_port}}) do
    # Check if this is an active pair (principal-to-principal)
    is_active = from_port == 1 && to_port == 1

    # Style based on active status
    style = if is_active, do: "===>", else: "--->"

    # Fixed: Proper Mermaid connection syntax
    "#{from_id} #{style}|#{from_port}↔#{to_port}| #{to_id}"
  end
end
