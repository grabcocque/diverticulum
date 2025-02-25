defmodule NetMancerTest do
  use ExUnit.Case
  doctest NetMancer

  test "simple addition evaluation" do
    # Create an Add function and the values 3 and 5
    net =
      NetMancer.new_net()
      # Create addition function with 2 ports (principal plus argument port)
      |> NetMancer.conjure_agent(:function, 2, {"Add", fn x -> x + 5 end})
      # Create value 3
      |> NetMancer.conjure_agent(:value, 1, 3)
      # Connect function's principal port to value's principal port
      |> NetMancer.forge_connection({1, 1}, {2, 1})

    IO.inspect(net.agents, label: "Agents")
    IO.inspect(net.connections, label: "Connections")

    # Evaluate the net and collect the Mermaid diagrams
    {result_net, diagrams} = NetMancer.evaluate(net)

    # Print the diagrams
    Enum.each(diagrams, &IO.puts/1)

    # Assert the final result to confirm expected behavior
    final_result = result_net.agents |> Map.values() |> hd() |> Map.get(:data)
    IO.puts("Final result: #{final_result}")
    assert final_result == 8

    assert_map_structure(result_net)
  end

  defp assert_map_structure(net) do
    assert is_map(net.agents)
    assert is_list(net.connections)
    assert length(net.connections) == length(net.agents) - 1

    Enum.each(net.agents, fn {_id, agent} ->
      assert Map.has_key?(agent, :id)
      assert Map.has_key?(agent, :data)
    end)

    assert length(net.agents) > 0
    assert Enum.all?(net.agents, fn {_id, agent} -> is_map(agent) end)

    Enum.each(net.agents, fn {_id, agent} ->
      assert Map.has_key?(agent, :id)
      assert Map.has_key?(agent, :data)
    end)

    Enum.each(net.agents, fn {_id, agent} ->
      assert Map.has_key?(agent, :type)
      assert Map.has_key?(agent, :connections)
      assert is_list(agent.connections)
    end)
  end
end
