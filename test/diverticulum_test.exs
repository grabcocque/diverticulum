defmodule NetMancerTest do
  use ExUnit.Case
  doctest NetMancer

  test "That reducing the net representing 3+5 results in 8" do
    net =
      NetMancer.new_net()
      # Create addition function with 2 ports (principal plus argument port)
      |> NetMancer.conjure_agent(:function, 2, {"Add 5", fn x -> x + 5 end})
      # Create value 3
      |> NetMancer.conjure_agent(:value, 1, 3)
      # Connect function's principal port to value's principal port
      |> NetMancer.forge_connection({1, 1}, {2, 1})

    IO.puts("### Initial net structure ###\n")

    agents = IO.inspect(net.agents, label: "Agents")
    connections = IO.inspect(net.connections, label: "Connections")

    assert_connections_structure(connections)
    assert_agent_structure(agents)

    IO.puts("\n### Reducing the net ###\n")
    initial_graph = NetMancer.mermaid_incantation(net)
    {result_net, graphs} = NetMancer.embrace_normalcy(net, [initial_graph])

    IO.puts("### Step-by-step graphs ###\n")
    Enum.each(graphs, &IO.puts/1)

    # Assert the final result to confirm expected behavior
    assert length(Map.keys(result_net.agents)) == 1, "Expected only one agent after reduction"

    assert length(Map.keys(result_net.connections)) == 0,
           "Expected no connections after reduction"

    final_result = result_net.agents |> Map.values() |> hd() |> Map.get(:data)
    IO.puts("### Final result: #{final_result} ###\n")
    assert final_result == 8
  end

  defp assert_connections_structure(connections) do
    assert length(Map.keys(connections)) > 0
    assert Enum.all?(connections, fn {from, to} -> is_tuple(from) and is_tuple(to) end)

    assert Enum.all?(connections, fn {from, to} ->
             is_integer(elem(from, 1)) and is_integer(elem(to, 1))
           end)

    assert Enum.all?(connections, fn {from, to} -> is_tuple(from) end)
    assert Enum.all?(connections, fn {from, to} -> is_tuple(to) end)
    assert Enum.all?(connections, fn {from, to} -> is_integer(elem(to, 1)) end)
  end

  defp assert_agent_structure(agents) do
    assert length(Map.keys(agents)) > 0
    assert Enum.all?(agents, fn {_id, agent} -> is_map(agent) end)

    assert Enum.all?(agents, fn {_id, agent} -> Map.has_key?(agent, :id) end)
    assert Enum.all?(agents, fn {_id, agent} -> Map.has_key?(agent, :type) end)
    assert Enum.all?(agents, fn {_id, agent} -> Map.has_key?(agent, :ports) end)
    assert Enum.all?(agents, fn {_id, agent} -> Map.has_key?(agent, :data) end)

    assert Enum.all?(agents, fn {_id, agent} -> is_list(agent.ports) end)
    assert Enum.all?(agents, fn {_id, agent} -> length(agent.ports) > 0 end)

    assert Enum.all?(agents, fn {_id, agent} ->
             Enum.all?(agent.ports, fn port -> is_integer(port) end)
           end)
  end
end
