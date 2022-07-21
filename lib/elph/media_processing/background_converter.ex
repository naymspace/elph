defmodule Elph.MediaProcessing.BackgroundConverter do
  @moduledoc """
  BackgroundConverter is a GenServer, that holds a queue of background jobs
  and distributes them to one `Task` at a time, supervised via a `Task.Supervisor`.
  This is made not to overwhelm the server with too many conversions at once.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, %{queue: [], current: nil}}
  end

  @impl true
  def handle_cast({:enqueue, fun}, %{current: nil} = state) do
    new_state = %{state | current: fun}

    run_task(fun)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:enqueue, fun}, %{queue: queue} = state) do
    new_state = %{state | queue: [fun | queue]}

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, %{queue: []} = state) do
    new_state = %{state | current: nil}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, %{queue: queue} = state) do
    {fun, rest} = List.pop_at(queue, -1)
    new_state = %{state | current: fun, queue: rest}

    run_task(fun)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp run_task(fun) do
    {:ok, pid} = Task.start(fun)
    Process.monitor(pid)
  end
end
