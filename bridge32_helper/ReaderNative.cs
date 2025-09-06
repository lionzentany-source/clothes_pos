using System;
using System.Runtime.InteropServices;

internal static class ReaderNative
{
    // Structures
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct TagInfo
    {
        public int len;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 64)]
        public byte[] code;
    }

    // P/Invoke signatures (stdcall assumed per samples)
    [DllImport("UHFPrimeReader.dll", CallingConvention = CallingConvention.StdCall)]
    public static extern int CFHid_GetUsbCount();

    [DllImport("UHFPrimeReader.dll", CallingConvention = CallingConvention.StdCall)]
    public static extern int OpenHidConnection(out IntPtr hComm, ushort index);

    [DllImport("UHFPrimeReader.dll", CallingConvention = CallingConvention.StdCall)]
    public static extern int CloseDevice(IntPtr hComm);

    [DllImport("UHFPrimeReader.dll", CallingConvention = CallingConvention.StdCall)]
    public static extern int InventoryContinue(IntPtr hComm, byte invCount, uint invParam);

    [DllImport("UHFPrimeReader.dll", CallingConvention = CallingConvention.StdCall)]
    public static extern int InventoryStop(IntPtr hComm, ushort timeoutMs);

    [DllImport("UHFPrimeReader.dll", CallingConvention = CallingConvention.StdCall)]
    public static extern int GetTagUii(IntPtr hComm, out TagInfo info, ushort timeoutMs);

    public const int ERROR_SUCCESS = 0x00;
    public const int ERROR_CMD_NO_TAG = 0x15;
}
