using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class DeviceConfigModel : BaseModel
    {
        private string _power;
        /// <summary>
        /// 输出功率
        /// </summary>
        public string Power
        {
            get { return _power; }
            set { Set(ref _power, value); }
        }

        private string _addr;
        /// <summary>
        /// 设备地址(HEX)
        /// </summary>
        public string Addr
        {
            get { return _addr; }
            set
            {
                value = value.FormatHexString();
                if (value == "FF") value = "0";
                if (value.String2HexArray().Length > 1) return;
                Set(ref _addr, value);
            }
        }

        private string _port;
        /// <summary>
        /// 通讯接口
        /// </summary>
        public string Port
        {
            get { return _port; }
            set { Set(ref _port, value); }
        }

        private int _portIndex;
        /// <summary>
        /// 通讯接口下标
        /// </summary>
        public int PortIndex
        {
            get { return _portIndex; }
            set { Set(ref _portIndex, value); }
        }

        private string _region;
        /// <summary>
        /// 工作频段
        /// </summary>
        public string Region
        {
            get { return _region; }
            set
            {
                Set(ref _region, value);
                BindComboBoxSource();
            }
        }

        public void BindComboBoxSource()
        {
            ChannelRegionItem region = ChannelRegionItem.OptionFromValue(ChannelRegionItem.StringToRegion(Region), false);// TODO 可配置
            if (region == null)
                return;

            if (region.Value != ChannelRegion.Custom)
            {
                StartFreqItem = region.GetChannelItems();
                EndFreqItem = region.GetChanelCounts();

                if (StartFreqItem.Length > 0)
                {
                    StartFreqIndex = 0;
                    StartFreq = StartFreqItem[StartFreqIndex].ToString();
                }
                if (EndFreqItem.Length > 0)
                {
                    OriEndFreqIndex = EndFreqIndex = EndFreqItem.Length - 1;
                    OriEndFreq = EndFreqItem[EndFreqIndex].ToString();
                }
            }
        }

        private int _regionIndex;
        /// <summary>
        /// 工作频段下标
        /// </summary>
        public int RegionIndex
        {
            get { return _regionIndex; }
            set { Set(ref _regionIndex, value); }
        }

        private string _startFreq;
        /// <summary>
        /// 起始频率
        /// </summary>
        public string StartFreq
        {
            get { return _startFreq; }
            set { Set(ref _startFreq, value); }
        }

        private int _startFreqIndex;
        /// <summary>
        /// 开始频率下标
        /// </summary>
        public int StartFreqIndex
        {
            get { return _startFreqIndex; }
            set { Set(ref _startFreqIndex, value); }
        }

        private string _endFreq;
        /// <summary>
        /// 结束频率
        /// </summary>
        public string EndFreq
        {
            get { return _endFreq; }
            set
            {
                Set(ref _endFreq, value);
                if (!string.IsNullOrEmpty(_endFreq) && string.IsNullOrEmpty(OriEndFreq))
                    OriEndFreq = _endFreq;
            }
        }

        private int _endFreqIndex;
        /// <summary>
        /// 结束频率下标
        /// </summary>
        public int EndFreqIndex
        {
            get { return _endFreqIndex; }
            set
            {
                Set(ref _endFreqIndex, value);
                if (_endFreqIndex != -1 && OriEndFreqIndex == -1)
                    OriEndFreqIndex = _endFreqIndex;
            }
        }

        public string OriEndFreq = string.Empty;
        public int OriEndFreqIndex = -1;

        private bool _isPointFreq = true;
        /// <summary>
        /// 单频点
        /// </summary>
        public bool IsPointFreq
        {
            get { return _isPointFreq; }
            set
            {
                Set(ref _isPointFreq, value);
                SetDeviceModelEndFreq(_isPointFreq);
            }
        }

        private bool _isNoPointFreq;

        public bool IsNoPointFreq
        {
            get { return _isNoPointFreq; }
            set
            {
                Set(ref _isNoPointFreq, value);
                SetDeviceModelEndFreq(!_isNoPointFreq);
            }
        }

        private void SetDeviceModelEndFreq(bool IsPointFreq)
        {
            if (IsPointFreq)
            {
                EndFreq = StartFreq;
                EndFreqIndex = StartFreqIndex;
            }
            else
            {
                EndFreq = OriEndFreq;
                EndFreqIndex = OriEndFreqIndex;
            }
        }

        private ChannelItem[] _startFreqItem;
        /// <summary>
        /// 
        /// </summary>
        public ChannelItem[] StartFreqItem
        {
            get { return _startFreqItem; }
            set { Set(ref _startFreqItem, value); }
        }

        private ChannelCountItem[] _endFreqItem;
        /// <summary>
        /// 
        /// </summary>
        public ChannelCountItem[] EndFreqItem
        {
            get { return _endFreqItem; }
            set { Set(ref _endFreqItem, value); }
        }

        private bool _isBuzzer = true;
        /// <summary>
        /// 蜂鸣器
        /// </summary>
        public bool IsBuzzer
        {
            get { return _isBuzzer; }
            set { Set(ref _isBuzzer, value); }
        }

        private bool _isNoBuzzer;
        public bool IsNoBuzzer
        {
            get { return _isNoBuzzer; }
            set { Set(ref _isNoBuzzer, value); }
        }
    }
}
