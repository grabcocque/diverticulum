# Diverticulum

A meditation on interaction

## Table of Contents

- [Diverticulum](#diverticulum)
- [Installation](#installation)
- [The Mystical Journey of Interaction Net Evaluation](#the-mystical-journey-of-interaction-net-evaluation)
  - [1. The Entry Point: evaluate/1](#1-the-entry-point-evaluate1)
  - [2. The Reduction Loop: reduce_until_normal/2](#2-the-reduction-loop-reduce_until_normal2)
  - [3. Finding & Applying Rules: try_apply_rule/1](#3-finding--applying-rules-try_apply_rule1)
  - [4. Identifying Active Pairs: find_active_pair/1](#4-identifying-active-pairs-find_active_pair1)
  - [5. Rewiring Connections: reconnect_ports/4](#5-rewiring-connections-reconnect_ports4)
- [For Our Addition Example](#6-for-our-addition-example)
- [The True Magic of Interaction Nets](#the-true-magic-of-interaction-nets)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `diverticulum` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diverticulum, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/```elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/diverticulum>.

## The Mystical Journey of Interaction Net Evaluation

Let me guide you through the entire process, from incantation to revelation:

### 1. The Entry Point: evaluate/1

```elixir
def evaluate(net) do
  {reduced_net, charts} = reduce_until_normal(net, [])
  {reduced_net, charts}
end
```

This function:

- Calls reduce_until_normal/2 to perform all possible reductions
- Collects Mermaid charts showing each step
- Returns the final net and all diagrams

### 2. The Reduction Loop: reduce_until_normal/2

```elixir
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
```

This function:

- Tries to apply a reduction rule to the current net
- If successful, creates a diagram of the result, then recursively continues
- If no more rules apply, returns the final net and all charts

### 3. Finding & Applying Rules: try_apply_rule/1

```elixir
defp try_apply_rule(net) do
  # Find the first active pair
  case find_active_pair(net) do
    {function_id, value_id} when function_id != nil ->
      # Get the agents
      function_agent = Map.get(net.agents, function_id)
      value_agent = Map.get(net.agents, value_id)
      
      # Extract function and value
      {_, func} = function_agent.data
      value_data = value_agent.data
      
      # Apply the function
      result = func.(value_data)
      
      # Create result agent and update net
      new_id = net.counter + 1
      result_agent = %{id: new_id, type: :value, ports: [1], data: result}
      
      new_net = %{net | 
        counter: new_id,
        agents: Map.put(
          Map.drop(net.agents, [function_id, value_id]),
          new_id, 
          result_agent
        )
      }
      
      # Reconnect remaining ports
      new_connections = reconnect_ports(net.connections, 
                                      function_id, 
                                      value_id, 
                                      new_id)
      
      {:apply, %{new_net | connections: new_connections}}
      
    nil ->
      :no_rule
  end
end
```

This function:

- Calls find_active_pair/1 to look for a reducible pair
- Extracts the function and value from the agents
- Applies the function to the value
- Creates a new agent to hold the result
- Removes the original agents
- Calls reconnect_ports/4 to rewire connections
- Returns the modified net

### 4. Identifying Active Pairs: find_active_pair/1

```elixir
defp find_active_pair(net) do
  # Look for connections between principal ports (port 1)
  Enum.find_value(net.connections, {nil, nil}, fn
    {{function_id, 1}, {value_id, 1}} ->
      function_agent = Map.get(net.agents, function_id)
      value_agent = Map.get(net.agents, value_id)
      
      if function_agent.type == :function && value_agent.type == :value do
        {function_id, value_id}
      else
        false
      end
    
    {{value_id, 1}, {function_id, 1}} ->
      function_agent = Map.get(net.agents, function_id)
      value_agent = Map.get(net.agents, value_id)
      
      if function_agent.type == :function && value_agent.type == :value do
        {function_id, value_id}
      else
        false
      end
      
    _ -> false
  end)
end
```

This function:

- Searches all connections for ones connecting principal ports
- Checks if one agent is a function and the other is a value
- Returns the IDs of the function and value agents if found

### 5. Rewiring Connections: reconnect_ports/4

```elixir
defp reconnect_ports(connections, function_id, value_id, new_id) do
  # Filter out direct connections between eliminated agents
  remaining_connections = connections
    |> Enum.reject(fn {{f_id, _}, {t_id, _}} ->
      (f_id == function_id && t_id == value_id) ||
      (f_id == value_id && t_id == function_id)
    end)
  
  # Remap connections to reference the new agent
  new_connections = remaining_connections
    |> Enum.map(fn {from, to} ->
      {from_id, from_port} = from
      {to_id, to_port} = to
      
      cond do
        # Rewire connections FROM eliminated agents
        from_id == function_id && from_port > 1 ->
          {{new_id, 1}, to}
          
        from_id == value_id && from_port > 1 ->
          {{new_id, 1}, to}
        
        # Rewire connections TO eliminated agents
        to_id == function_id && to_port > 1 ->
          {from, {new_id, 1}}
          
        to_id == value_id && to_port > 1 ->
          {from, {new_id, 1}}
          
        # Keep others unchanged
        true -> {from, to}
      end
    end)
    |> Map.new()
    
  new_connections
end
```

This function:

- Removes connections between the eliminated agents
- Rewires connections from auxiliary ports to the new result agent
- Rewires connections to auxiliary ports from the new result agent
- Preserves all other connections

### 6. For Our Addition Example

```elixir
net = NetMancer.new_net()
|> NetMancer.conjure_agent(:function, 2, {"Add", fn x -> x + 5 end})
|> NetMancer.conjure_agent(:value, 1, 3)
|> NetMancer.forge_connection({1, 1}, {2, 1})
```

- Initial Net:
  - Agent 1: Function "Add" with ports [1, 2]
  - Agent 2: Value 3 with port [1]
  - Connection: (1,1) ↔ (2,1) - an active pair!

- First Reduction:
  - find_active_pair finds agents 1 and 2
  - Function fn x -> x + 5 end is applied to value 3, giving 8
  - Agents 1 and 2 are removed
  - New agent 3 is created with value 8
  - Connections are rewired (none in this simple case)

- Final State:
  - Agent 3: Value 8 with port [1]
  - No connections
  - No more active pairs, so evaluation is complete

The diagrams generated at each step show this transformation visually via Mermaid.

## The True Magic of Interaction Nets

- Locality: All computation is local - only active pairs interact
- Parallelism: Multiple active pairs can reduce independently
- Determinism: The order of reductions doesn't affect the final result

Like an arcade game's deterministic logic, the interaction net follows these rigid rules to reach its final form, regardless of the order of moves! 🎮✨
