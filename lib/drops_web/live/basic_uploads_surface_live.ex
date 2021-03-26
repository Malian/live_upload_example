defmodule DropsWeb.BasicUploadsSurfaceLive do
  use DropsWeb, :surface_live_view

  data(exhibit, :upload,
    accept: ~w(video/* image/*),
    max_entries: 6,
    chunk_size: 1_024,
    progress: &handle_progress/3,
    auto_upload: true
  )

  data(uploaded_files, :list, default: [])

  @impl true
  def handle_event("validate", _params, socket) do
    socket = update_data_upload(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    socket =
      socket
      |> cancel_upload(:exhibit, ref)
      |> update_data_upload()

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :exhibit, fn %{path: path}, _entry ->
        dest = Path.join(Drops.uploads_priv_dir(), Path.basename(path))
        File.cp!(path, dest)
        Routes.static_path(socket, "/uploads/#{Path.basename(dest)}")
      end)

    socket =
      socket
      |> update(:uploaded_files, &(&1 ++ uploaded_files))
      |> update_data_upload()

    {:noreply, socket}
  end

  def handle_progress(_, _, socket) do
    # socket = update_data_upload(socket)
    {:noreply, socket}
  end

  defp update_data_upload(socket) do
    Enum.reduce(socket.assigns.uploads, socket, fn
      {_key, %Phoenix.LiveView.UploadConfig{name: name} = config}, socket ->
        assign(socket, name, config)

      {_, _}, _ ->
        socket
    end)
  end
end
