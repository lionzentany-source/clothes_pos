using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

class Program
{
    private static IntPtr _hComm = IntPtr.Zero;
    private static CancellationTokenSource? _inventoryCts;

    static async Task<int> Main()
    {
        Console.OutputEncoding = Encoding.UTF8;
        try
        {
            int count = ReaderNative.CFHid_GetUsbCount();
            if (count <= 0)
            {
                await WriteEvent(new OutEvent("error", Message: "No HID reader found"));
                return 2;
            }
            int openRes = ReaderNative.OpenHidConnection(out _hComm, 0);
            if (openRes != ReaderNative.ERROR_SUCCESS || _hComm == IntPtr.Zero)
            {
                await WriteEvent(new OutEvent("error", Message: $"OpenHidConnection failed: {openRes}"));
                return 3;
            }
            await WriteEvent(new OutEvent("ready"));

            // Command loop
            using var reader = Console.In;
            string? line;
            while ((line = await reader.ReadLineAsync()) != null)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                InCommand? cmd;
                try
                {
                    cmd = JsonSerializer.Deserialize<InCommand>(line);
                }
                catch (Exception ex)
                {
                    await WriteEvent(new OutEvent("error", Message: $"Bad JSON: {ex.Message}"));
                    continue;
                }
                if (cmd == null) continue;

                switch (cmd.Cmd?.ToLowerInvariant())
                {
                    case "start":
                        StartInventory();
                        break;
                    case "stop":
                        StopInventory();
                        break;
                    case "shutdown":
                        StopInventory();
                        goto EXIT;
                }
            }
        }
        catch (Exception ex)
        {
            await WriteEvent(new OutEvent("error", Message: ex.Message));
        }
    EXIT:
        StopInventory();
        if (_hComm != IntPtr.Zero)
        {
            try { ReaderNative.CloseDevice(_hComm); } catch { }
            _hComm = IntPtr.Zero;
        }
        return 0;
    }

    private static async Task WriteEvent(OutEvent evt)
    {
        Console.WriteLine(JsonSerializer.Serialize(evt));
        await Console.Out.FlushAsync();
    }

    private static void StartInventory()
    {
        if (_inventoryCts != null) return; // already running
        int res = ReaderNative.InventoryContinue(_hComm, 0xFF, 0);
        if (res != ReaderNative.ERROR_SUCCESS)
        {
            _ = WriteEvent(new OutEvent("error", Message: $"InventoryContinue failed: {res}"));
            return;
        }
        _inventoryCts = new CancellationTokenSource();
        var token = _inventoryCts.Token;
        Task.Run(async () =>
        {
            while (!token.IsCancellationRequested)
            {
                try
                {
                    var info = new ReaderNative.TagInfo { code = new byte[64] };
                    int codeRes = ReaderNative.GetTagUii(_hComm, out info, 200);
                    if (codeRes == ReaderNative.ERROR_SUCCESS && info.len > 0)
                    {
                        var epcBytes = new byte[info.len];
                        Array.Copy(info.code, epcBytes, info.len);
                        var sb = new StringBuilder();
                        foreach (var b in epcBytes)
                            sb.Append(b.ToString("X2"));
                        await WriteEvent(new OutEvent("tag", Epc: sb.ToString()));
                    }
                }
                catch (Exception ex)
                {
                    await WriteEvent(new OutEvent("error", Message: ex.Message));
                }
                await Task.Delay(120, token).ConfigureAwait(false);
            }
        }, token);
    }

    private static void StopInventory()
    {
        if (_inventoryCts == null) return;
        try
        {
            ReaderNative.InventoryStop(_hComm, 1000);
        }
        catch { }
        _inventoryCts.Cancel();
        _inventoryCts.Dispose();
        _inventoryCts = null;
    }
}
