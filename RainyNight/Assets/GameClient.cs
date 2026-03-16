using System;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class GameClient : MonoBehaviour
{
    [Header("服务器配置")]
    [SerializeField] private string host = "127.0.0.1";
    [SerializeField] private int port = 5000;

    private TcpClient _client;
    private NetworkStream _stream;
    private CancellationTokenSource _cts;
    private bool _isConnected = false;

    public bool IsConnected => _isConnected;

    private async void Start()
    {
        await ConnectAsync();
    }

    private void Update()
    {
        // 按空格发送测试消息
        if (Input.GetKeyDown(KeyCode.Space))
        {
            SendMessageToServer("ping");
        }

        if (Input.GetKeyDown(KeyCode.T))
        {
            SendMessageToServer("time");
        }
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

            Debug.Log("[Client] 连接服务器成功。");

            _ = ReceiveLoopAsync(_cts.Token);
        }
        catch (Exception ex)
        {
            Debug.LogError($"[Client] 连接失败: {ex.Message}");
            _isConnected = false;
        }
    }

    public async void SendMessageToServer(string msg)
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
            while (!token.IsCancellationRequested && _client != null && _client.Connected)
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
        catch (Exception ex)
        {
            Debug.LogError($"[Client] 接收异常: {ex.Message}");
        }
        finally
        {
            Disconnect();
        }
    }

    private void HandleServerMessage(string msg)
    {
        Debug.Log($"[Client] 收到服务端消息: {msg}");

        // 后面你可以在这里做协议分发
        // 比如：
        // if (msg == "pong") { ... }
    }

    public void Disconnect()
    {
        if (!_isConnected && _client == null)
            return;

        _isConnected = false;

        try { _cts?.Cancel(); } catch { }
        try { _stream?.Close(); } catch { }
        try { _client?.Close(); } catch { }

        _stream = null;
        _client = null;
        _cts = null;

        Debug.Log("[Client] 已断开连接。");
    }

    private void OnDestroy()
    {
        Disconnect();
    }

    private void OnApplicationQuit()
    {
        Disconnect();
    }
}