/// Basic interface for a panel-backed runtime view.
abstract interface class PanelView {}

/// Abstract API for a realtime panel view used by the devtool and the
/// extension. This is intentionally abstract — concrete implementations
/// (for example WebSocket-based connectors) should implement this API.
abstract class RealtimePanelView implements PanelView {
	/// Connect to the remote controller. Implementations decide how
	/// connection happens (WebSocket, local domain socket, etc.).
	Future<void> connect(String url);

	/// Disconnect the current connection and stop any automatic reconnect.
	Future<void> disconnect();

	/// Whether the transport is currently connected.
	bool get isConnected;

	/// Register a handler for events with the given name.
	void on(String event, void Function(Map<String, dynamic> payload) handler);

	/// Remove a handler previously registered with [on].
	void off(String event, void Function(Map<String, dynamic> payload) handler);

	/// Send a generic typed event to the remote side.
	void send(String type, Map<String, dynamic> payload);

	/// Convenience helpers commonly used by the runtime panel UI.
	void sendStarted({required String url});
	void requestPodsList();
	void requestPodDetails(String name);
	void sendShowPod(String name);
	void sendCommand(String command, [Map<String, dynamic> args]);
}

