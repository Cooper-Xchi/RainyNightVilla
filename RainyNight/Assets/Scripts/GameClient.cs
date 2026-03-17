using System;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class GameClient : MonoBehaviour
{
    public static GameClient Instance { get; private set; }

    [Header("服务器配置")]
    [SerializeField] private string host = "139.227.85.49";
    [SerializeField] private int port = 33389;

    private TcpClient _client;
    private NetworkStream _stream;
    private CancellationTokenSource _cts;
    private bool _isConnected = false;
    private bool _isDisconnecting = false;

    public bool IsConnected => _isConnected;

    private async void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }

        Instance = this;
        DontDestroyOnLoad(gameObject);

        await ConnectAsync();
    }

    public async Task ConnectAsync()
    {
        if (_isConnected)
        {
            Debug.Log("[Client] 已经连接到服务器。");
            return;
        }

        try
        {
            _cts = new CancellationTokenSource();
            _client = new TcpClient();

            Debug.Log($"[Client] 正在连接服务器 {host}:{port} ...");
            await _client.ConnectAsync(host, port);

            _stream = _client.GetStream();
            _isConnected = true;
            _isDisconnecting = false;

            Debug.Log("[Client] 连接服务器成功。");

            // 向服务器发送连接成功消息
            await SendMessageToServer("连接成功");

            _ = ReceiveLoopAsync(_cts.Token);
        }
        catch (Exception ex)
        {
            Debug.LogError($"[Client] 连接失败: {ex.Message}");
            _isConnected = false;
        }
    }

    public async 
    Task
SendMessageToServer(string msg)
    {
        if (!_isConnected || _stream == null)
        {
            Debug.LogWarning("[Client] 当前未连接服务器，无法发送消息。");
            return;
        }

        if (string.IsNullOrWhiteSpace(msg))
            return;

        try
        {
            string finalMsg = msg + "\n";
            byte[] data = Encoding.UTF8.GetBytes(finalMsg);

            await _stream.WriteAsync(data, 0, data.Length);
            await _stream.FlushAsync();

            Debug.Log($"[Client] 已发送: {msg}");
        }
        catch (Exception ex)
        {
            Debug.LogError($"[Client] 发送失败: {ex.Message}");
            Disconnect();
        }
    }

    private async Task ReceiveLoopAsync(CancellationToken token)
    {
        byte[] buffer = new byte[4096];
        StringBuilder sb = new StringBuilder();

        try
        {
            while (!token.IsCancellationRequested && _client != null)
            {
                int len = await _stream.ReadAsync(buffer, 0, buffer.Length, token);

                if (len <= 0)
                {
                    Debug.LogWarning("[Client] 服务器断开连接。");
                    break;
                }

                string recvText = Encoding.UTF8.GetString(buffer, 0, len);
                sb.Append(recvText);

                while (true)
                {
                    string current = sb.ToString();
                    int index = current.IndexOf('\n');
                    if (index < 0)
                        break;

                    string oneMsg = current.Substring(0, index).Trim('\r');
                    sb.Remove(0, index + 1);

                    if (!string.IsNullOrWhiteSpace(oneMsg))
                    {
                        HandleServerMessage(oneMsg);
                    }
                }
            }
        }
        catch (OperationCanceledException)
        {
        }
        catch (ObjectDisposedException)
        {
        }
        catch (Exception ex)
        {
            if (!_isDisconnecting)
            {
                Debug.LogError($"[Client] 接收异常: {ex.Message}");
            }
        }
        finally
        {
            if (!_isDisconnecting)
            {
                Disconnect();
            }
        }
    }

    private void HandleServerMessage(string msg)
    {
        Debug.Log($"[Client] 收到服务端消息: {msg}");
    }

    public void Disconnect()
    {
        if (_isDisconnecting)
            return;

        _isDisconnecting = true;
        _isConnected = false;

        try { _cts?.Cancel(); } catch { }

        try
        {
            if (_client != null && _client.Client != null && _client.Client.Connected)
            {
                _client.Client.Shutdown(SocketShutdown.Both);
            }
        }
        catch { }

        try { _stream?.Close(); } catch { }
        try { _client?.Close(); } catch { }
        try { _cts?.Dispose(); } catch { }

        _stream = null;
        _client = null;
        _cts = null;

        Debug.Log("[Client] 已断开连接。");
    }

    private void OnApplicationQuit()
    {
        Disconnect();
    }

    private void OnDestroy()
    {
        if (Instance == this)
        {
            Disconnect();
            Instance = null;
        }
    }
}