using System;
using System.Net.NetworkInformation;
using System.Reflection;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class ReaderModel : BaseModel
    {
        private string _ConnectType;
        public string ConnectType
        {
            get { return _ConnectType; }
        }

        public int Status
        {
            get { return _reader.m_iState; }
        }

        public int Handler
        {
            get { return (int)_reader.m_handler; }
        }

        public int Devicetpye
        {
            get { return _reader.devicetpye; }
        }

        private string _hardwareVersion;
        /// <summary>
        /// 硬件版本
        /// </summary>
		[Ignore(true)]
        public string HardwareVersion
        {
            get { return _hardwareVersion; }
            set { Set(ref _hardwareVersion, value); }
        }

        private string _firmwareVersion;
        /// <summary>
        /// 软件版本
        /// </summary>
		[Ignore(true)]
        public string FirmwareVersion
        {
            get { return _firmwareVersion; }
            set { Set(ref _firmwareVersion, value); }
        }

        private string _deviceSN;
        /// <summary>
        /// 设备SN
        /// </summary>
		[Ignore(true)]
        public string DeviceSN
        {
            get { return _deviceSN; }
            set { Set(ref _deviceSN, value); }
        }

        private static NetReader _reader;

        private static DeviceModel _device;
        public ReaderModel(NetReader reader)
        {
            _reader = reader;
        }

        public NetReader CurrentReader { get { return _reader; } }
        public DeviceModel CurrentDevice { get { return _device; } }

        public bool Open(ushort index)
        {
            string tip;
            _reader.Open(index);
            _device = new DeviceModel(_reader, out tip);
            InventoryStop();
            InitReader();
            if (!FirmwareVersion.Contains("Desk"))
            {
                CloseReader();
                return false;
            }
            _ConnectType = "USB";
            return true;
        }

        public bool Open(string port, byte baudIndex)
        {
            string tip;
            _reader.Open(port, baudIndex);
            _device = new DeviceModel(_reader, out tip);
            InventoryStop();
            InitReader();
            if (!FirmwareVersion.Contains("Desk"))
            {
                CloseReader();
                return false;
            }
            _ConnectType = "COM";
            return true;
        }

        public void InventoryStop()
        {
            try
            {
                _reader.ISO.InventoryStop(10000);
            }
            catch (Exception ex)
            { }
        }

        public void CloseReader()
        {
            _reader.Close();
        }

        public void InitReader()
        {
            DeviceFullInfo _info = _reader.GetDeviceFullInfo();
            HardwareVersion = _info.DeviceHardwareVersion;
            FirmwareVersion = _info.DeviceFirmwareVersion;
            DeviceSN = _info.DeviceSN.HexArray2String();
        }
    }
}
