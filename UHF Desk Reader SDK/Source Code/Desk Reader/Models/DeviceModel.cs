using System;
using System.Collections.ObjectModel;
using System.Text;
using System.Text.Json.Serialization;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class DeviceModel : BaseModel
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

        private string _baud;
        /// <summary>
        /// 波特率
        /// </summary>
        public string Baud
        {
            get { return _baud; }
            set { Set(ref _baud, value); }
        }

        private int _baudIndex;
        /// <summary>
        /// 波特率下标
        /// </summary>
        public int BaudIndex
        {
            get { return _baudIndex; }
            set { _baudIndex = value; }
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
                if (value.String2HexArray().Length > 1) return;
                Set(ref _addr, value);
            }
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
            set { Set(ref _isNoPointFreq, value); }
        }

        private void SetDeviceModelEndFreq(bool IsPointFreq)
        {
            if (IsPointFreq)
            {
                EndFreq = StartFreq;
                EndFreqIndex = StartFreqIndex;
                IsNoPointFreq = false;
            }
            else
            {
                EndFreq = OriEndFreq;
                EndFreqIndex = OriEndFreqIndex;
                IsNoPointFreq = true;
            }
        }

        private string _workmode;
        /// <summary>
        /// 工作模式
        /// </summary>
        public string Workmode
        {
            get { return _workmode; }
            set { Set(ref _workmode, value); }
        }

        private int _workmodeIndex;
        /// <summary>
        /// 工作模式下标
        /// </summary>
        public int WorkmodeIndex
        {
            get { return _workmodeIndex; }
            set { Set(ref _workmodeIndex, value); }
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

        private string _area;
        /// <summary>
        /// 区域号码
        /// </summary>
        public string Area
        {
            get { return _area; }
            set { Set(ref _area, value); }
        }

        private int _areaIndex;
        /// <summary>
        /// 区域号码下标
        /// </summary>
        public int AreaIndex
        {
            get { return _areaIndex; }
            set { Set(ref _areaIndex, value); }
        }

        private string _startaddr;
        /// <summary>
        /// 起始地址
        /// </summary>
        public string Startaddr
        {
            get { return _startaddr; }
            set { Set(ref _startaddr, value); }
        }

        private string _dataLen;
        /// <summary>
        /// 字节长度
        /// </summary>
        public string DataLen
        {
            get { return _dataLen; }
            set { Set(ref _dataLen, value); }
        }

        private string _filtertime;
        /// <summary>
        /// 过滤时间
        /// </summary>
        public string Filtertime
        {
            get { return _filtertime; }
            set { Set(ref _filtertime, value); }
        }

        private string _triggletime;
        /// <summary>
        /// 触发时间
        /// </summary>
        public string Triggletime
        {
            get { return _triggletime; }
            set { Set(ref _triggletime, value); }
        }

        private string _intenelTime;
        /// <summary>
        /// 查询间隔时间
        /// </summary>
        public string IntenelTime
        {
            get { return _intenelTime; }
            set { Set(ref _intenelTime, value); }
        }

        private string _q;
        /// <summary>
        /// Q值
        /// </summary>
        public string Q
        {
            get { return _q; }
            set { Set(ref _q, value); }
        }

        private string _session;
        /// <summary>
        /// Session
        /// </summary>
        public string Session
        {
            get { return _session; }
            set { Set(ref _session, value); }
        }

        private int _sessionIndex;
        /// <summary>
        /// Session下标
        /// </summary>
        public int SessionIndex
        {
            get { return _sessionIndex; }
            set { Set(ref _sessionIndex, value); }
        }

        private string _wiegandMode;
        /// <summary>
        /// 韦根输出
        /// </summary>
        public string WiegandMode
        {
            get { return _wiegandMode; }
            set { Set(ref _wiegandMode, value); }
        }

        private string _wieggendOutMode;
        /// <summary>
        /// 韦根输出
        /// </summary>
        public string WieggendOutMode
        {
            get { return _wieggendOutMode; }
            set { Set(ref _wieggendOutMode, value); }
        }

        private ChannelItem[] _startFreqItem;
        /// <summary>
        /// 
        /// </summary>
        [JsonIgnore(Condition = JsonIgnoreCondition.Always)]
        [Ignore(true)]
        public ChannelItem[] StartFreqItem
        {
            get { return _startFreqItem; }
            set { Set(ref _startFreqItem, value); }
        }

        private ChannelCountItem[] _endFreqItem;
        /// <summary>
        /// 
        /// </summary>
        [JsonIgnore(Condition = JsonIgnoreCondition.Always)]
        [Ignore(true)]
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
            set
            {
                Set(ref _isBuzzer, value);
                IsNoBuzzer = !value;
            }
        }

        private bool _isNoBuzzer;
        [Ignore(true)]
        public bool IsNoBuzzer
        {
            get { return _isNoBuzzer; }
            set { Set(ref _isNoBuzzer, value); }
        }

        private bool _isAnswer;
        /// <summary>
        /// 应答模式
        /// </summary>
        public bool IsAnswer
        {
            get { return _isAnswer; }
            set
            {
                Set(ref _isAnswer, value);
                if (_isAnswer)
                {
                    WorkmodeIndex = 0;
                    IsAnswerStop1 = true;
                    MS = "0";
                }
            }
        }

        private bool _isTrigger;
        /// <summary>
        /// 触发模式
        /// </summary>
        public bool IsTrigger
        {
            get { return _isTrigger; }
            set
            {
                Set(ref _isTrigger, value);
                if (_isTrigger)
                {
                    WorkmodeIndex = 2;
                    IsTriggerStop = true;
                }
            }
        }

        private bool _isAnto;
        /// <summary>
        /// 主动模式
        /// </summary>
        public bool IsAnto
        {
            get { return _isAnto; }
            set
            {
                Set(ref _isAnto, value);
                if (_isAnto)
                {
                    WorkmodeIndex = 1;
                    IsAntoStop = true;
                }
            }
        }

        private bool _isAnswerStop1;
        /// <summary>
        /// 应答模式 - 根据时间
        /// </summary>
        public bool IsAnswerStop1
        {
            get { return _isAnswerStop1; }
            set { Set(ref _isAnswerStop1, value); }
        }

        private bool _isAnswerStop2;
        /// <summary>
        /// 应答模式 - 根据次数
        /// </summary>
        public bool IsAnswerStop2
        {
            get { return _isAnswerStop2; }
            set { Set(ref _isAnswerStop2, value); }
        }

        private bool _isTriggerStop;
        /// <summary>
        /// 触发模式
        /// </summary>
        public bool IsTriggerStop
        {
            get { return _isTriggerStop; }
            set { Set(ref _isTriggerStop, value); }
        }

        private bool _isAntoStop;
        /// <summary>
        /// 主动模式
        /// </summary>
        public bool IsAntoStop
        {
            get { return _isAntoStop; }
            set { Set(ref _isAntoStop, value); }
        }

        private string _ms;
        /// <summary>
        /// 
        /// </summary>
        public string MS
        {
            get { return _ms; }
            set { Set(ref _ms, value); }
        }

        private string _inventoryRounds;
        /// <summary>
        /// 
        /// </summary>
        public string InventoryRounds
        {
            get { return _inventoryRounds; }
            set { Set(ref _inventoryRounds, value); }
        }

        private bool _antennaEnabled;
        /// <summary>
        /// 天线使能
        /// </summary>
        public bool AntennaEnabled
        {
            get { return _antennaEnabled; }
            set { Set(ref _antennaEnabled, value); }
        }

        private NetReader _reader;
        private DeviceParam param;

        public DeviceModel(NetReader reader, out string Tip)
        {
            _reader = reader;
            InitDevice(out Tip);
        }

        public void InitDevice(out string Tip)
        {
            try
            {
                Tip = "";
                param = _reader.GetDevicePara();
                Power = param.Power.ToString();

                BaudIndex = param.Baud;
                switch (param.Baud.ToString())
                {
                    case "0":
                        Baud = "9600";
                        break;
                    case "1":
                        Baud = "19200";
                        break;
                    case "2":
                        Baud = "38400";
                        break;
                    case "3":
                        Baud = "57600";
                        break;
                    case "4":
                        Baud = "115200";
                        break;
                    default: break;
                }

                Addr = param.Addr.ToString("X");


                FreqInfo freq = new FreqInfo();
                freq.Region = param.Region;
                freq.StartFreq = param.StartFreq + param.StartFreqde / 1000.0f;
                freq.StepFreq = param.Stepfreq;
                freq.Count = (byte)(param.Channel - 1);
                ChannelRegionItem region = ChannelRegionItem.OptionFromValue((ChannelRegion)freq.Region, false); // TODO 可配置
                RegionIndex = param.Region;
                switch (region.Value)
                {
                    case ChannelRegion.USA:
                        Region = "USA";
                        break;
                    case ChannelRegion.Korea:
                        Region = "Korea";
                        break;
                    case ChannelRegion.Europe:
                        Region = "Europe";
                        break;
                    case ChannelRegion.Japan:
                        Region = "Japan";
                        break;
                    case ChannelRegion.Malaysia:
                        Region = "Malaysia";
                        break;
                    case ChannelRegion.Europe3:
                        Region = "Europe3";
                        break;
                    case ChannelRegion.China_1:
                        Region = "China_1";
                        break;
                    case ChannelRegion.China_2:
                        Region = "China_2";
                        break;
                    default:
                        Region = "Custom";
                        break;
                }
                StartFreq = freq.StartFreq.ToString("F3");
                EndFreq = (freq.StartFreq + freq.StepFreq / 1000.0f * freq.Count).ToString("F3");

                WorkmodeIndex = param.Workmode;
                switch (param.Workmode.ToString())
                {
                    case "0":
                        IsAnswer = true;
                        int ms;
                        int count;
                        if (GlobalModel.TriggerType == "0" && int.TryParse(GlobalModel.TriggerContent, out ms))
                        {
                            // 按时间
                            IsAnswerStop1 = true;
                            MS = ms.Obj2String();
                        }
                        else if (GlobalModel.TriggerType == "1" && int.TryParse(GlobalModel.TriggerContent, out count))
                        {
                            // 按次数
                            IsAnswerStop2 = true;
                            IsAnswerStop1 = false;
                            InventoryRounds = count.Obj2String();
                        }
                        else
                        {
                            // 默认值
                            IsAnswerStop1 = true;
                            MS = "0";
                        }
                        if (GlobalModel.IsChinese)
                            Workmode = "应答模式";
                        else
                            Workmode = "Answer Mode";
                        break;
                    case "1":
                        IsAnto = true;
                        IsAntoStop = true;
                        if (GlobalModel.IsChinese)
                            Workmode = "主动模式";
                        else
                            Workmode = "Active Mode";
                        break;
                    case "2":
                        IsTrigger = true;
                        IsTriggerStop = true;
                        if (GlobalModel.IsChinese)
                            Workmode = "触发模式";
                        else
                            Workmode = "Trigger Mode";
                        break;
                    default: break;
                }

                switch (param.port)
                {
                    case 0x01:
                        Port = "USB";
                        PortIndex = 0;
                        break;
                    case 0x02:
                        Port = "KeyBoard";
                        PortIndex = 1;
                        break;
                    case 0x04:
                        Port = "CDC_COM";
                        PortIndex = 2;
                        break;
                    default: break;
                }
                byte wieggand = param.wieggand;
                if (wieggand >> 7 == 1)
                {
                    PortIndex = 3;//韦根输出
                    Port = "Wieggand";
                }
                WiegandMode = (wieggand & 0x20) != 0 ? "WG34" : "WG26";
                if (GlobalModel.IsChinese)
                    WieggendOutMode = (wieggand & 0x20) != 0 ? "高字节在前输出" : "低字节在前输出";
                else
                    WieggendOutMode = (wieggand & 0x20) != 0 ? "High Bytes Are Output First" : "Low Bytes Are Output First";

                AreaIndex = param.Area;
                switch (param.Area.ToString())
                {
                    case "0":
                        Area = "Reserve";
                        break;
                    case "1":
                        Area = "EPC";
                        break;
                    case "2":
                        Area = "TID";
                        break;
                    case "3":
                        Area = "User";
                        break;
                    case "4":
                        Area = "EPC+TID";
                        break;
                    case "5":
                        Area = "EPC+User";
                        break;
                    case "6":
                        Area = "EPC+TID+User";
                        break;
                    default: break;
                }

                Startaddr = param.Startaddr.ToString("D");
                DataLen = param.DataLen.ToString("D");
                Filtertime = param.Filtertime.ToString();
                Triggletime = param.Triggletime.ToString();
                IntenelTime = param.IntenelTime.ToString("D");
                Q = param.Q.ToString();

                SessionIndex = param.Session;
                switch (param.Session.ToString())
                {
                    case "0":
                        Session = "S0";
                        break;
                    case "1":
                        Session = "S1";
                        break;
                    case "2":
                        Session = "S2";
                        break;
                    case "3":
                        Session = "S3";
                        break;
                    case "4":
                        Session = "Auto";
                        break;
                    default: break;
                }

                if (StartFreq.Equals(EndFreq))
                    IsPointFreq = true;
                else
                    IsPointFreq = false;
                BindComboBoxSource();
                if (param.Buzzertime != 0) IsBuzzer = true;
                else IsBuzzer = false;

                IsChanged = false;
            }
            catch (Exception ex)
            {
                Tip = ex.Message;
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

        public void SetDevice(out string Tip)
        {
            try
            {
                Tip = "";
                if (!IsChanged) return;

                param.Addr = (byte)Addr.String2Hex();
                param.Baud = (byte)BaudIndex;
                param.Protocol = 0;
                param.Workmode = (byte)WorkmodeIndex;

                if (WorkmodeIndex == 0)
                {
                    ConfigurationExtend.UpdateAppConfig("trigger_type", IsAnswerStop1 ? "0" : "1");
                    ConfigurationExtend.UpdateAppConfig("trigger_content", IsAnswerStop1 ? MS : InventoryRounds);
                }
                param.Region = (byte)RegionIndex;
                param.Ant = 1;

                int port = PortIndex;
                switch (port)
                {
                    case 0:  //USB
                        param.port = 0x01;
                        param.wieggand = 0x00;
                        break;
                    case 1:  //Keyboard
                        param.port = 0x02;
                        param.wieggand = 0x00;
                        break;
                    case 2:  //CDC_COM
                        param.port = 0x04;
                        param.wieggand = 0x00;
                        break;
                    default: break;
                }

                FreqInfo info = new FreqInfo();

                ChannelRegionItem region = ChannelRegionItem.OptionFromValue(ChannelRegionItem.StringToRegion(Region), false); // TODO 可配置
                if (region == null)
                    return;

                float endFreq;
                float startFreq;
                int step;
                int count;
                if (region.Value == 0)
                {
                    string starfreq = StartFreq;
                    if (starfreq.Length == 0)
                        throw new Exception("请输入起始频率!");
                    step = 500;
                    string endfreq = EndFreq;

                    if (!float.TryParse(starfreq, out startFreq) || startFreq < 840 || startFreq > 960)
                        throw new Exception("起始频率输入有误,请确认!");
                    if (!float.TryParse(endfreq, out endFreq) || endFreq < 840 || endFreq > 960)
                        throw new Exception("结束频率输入有误,请确认!");

                    count = (int)(endFreq - startFreq) / step;
                    if (count < 1 || count > 50)
                        throw new Exception("起始频率或结束频率输入有误,请确认!");
                }
                else
                {
                    ChannelItem item = StartFreqItem[StartFreqIndex];
                    if (item == null)
                        throw new Exception("起始频率选择错误,请确认!");
                    startFreq = item.Freq;
                    ChannelCountItem cnt = EndFreqItem[EndFreqIndex];
                    if (cnt == null)
                        throw new Exception("结束频率选择错误,请确认!");
                    count = EndFreqIndex - StartFreqIndex + 1;
                    endFreq = startFreq + region.FreqStep * count;
                }
                // 不能动  
                float i = startFreq * 1000;
                param.StartFreq = (ushort)startFreq;
                // 精度问题，浮点数运算会丢失
                param.StartFreqde = (ushort)(i - (int)startFreq * 1000);
                param.Stepfreq = (ushort)region.FreqStep;
                param.Channel = (byte)count;

                param.Power = (byte)Power.Obj2Int();
                param.Area = (byte)AreaIndex;
                param.Q = (byte)Q.Obj2Int();
                param.Session = (byte)SessionIndex;
                param.Startaddr = (byte)Startaddr.Obj2Int();
                param.DataLen = (byte)DataLen.Obj2Int();
                param.Filtertime = (byte)Filtertime.Obj2Int();
                param.Triggletime = (byte)Triggletime.Obj2Int();
                param.IntenelTime = (byte)IntenelTime.Obj2Int();
                param.Buzzertime = IsBuzzer ? (byte)1 : (byte)0;

                _reader.SetDevicePara(param);

                IsChanged = false;
            }
            catch (Exception ex)
            {
                Tip = ex.Message;
            }
        }
    }
}
