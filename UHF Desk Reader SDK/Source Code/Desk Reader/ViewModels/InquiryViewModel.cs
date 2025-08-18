using GalaSoft.MvvmLight.Command;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Markup;
using System.Windows.Media;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class InquiryViewModel : BaseViewModel
    {
        #region Fileds

        Dictionary<string, MonitorConfigModel> dicConfig = new Dictionary<string, MonitorConfigModel>();
        /// <summary>
        /// 是否第一次发停止监控指令
        /// </summary>
        private bool firstStop = false;
        private int stopCount;
        // 开始监控的时间
        private int m_iInvStartTick;
        // 当前秒速速
        private int m_RecognitionSpeed;
        // 从开始监控经过的秒数
        private int m_second;
        // 是否更新速度
        private bool m_isRenew;
        public string ModifyCode;

        #endregion

        #region Properties

        private bool _isMonitor = false;
        /// <summary>
        /// 是否停止监控
        /// </summary>
        public bool IsMonitor
        {
            get { return _isMonitor; }
            set
            {
                Set(ref _isMonitor, value);
                SetButtonStyle();
            }
        }

        private string _buttonIcon = "\ue602";
        /// <summary>
        /// 按钮图标
        /// </summary>
        public string ButtonIcon
        {
            get { return _buttonIcon; }
            set { Set(ref _buttonIcon, value); }
        }

        private string _buttonText = "START";
        /// <summary>
        /// 按钮文本
        /// </summary>
        public string ButtonText
        {
            get { return _buttonText; }
            set { Set(ref _buttonText, value); }
        }

        private MonitorConfigModel _config = new MonitorConfigModel();
        /// <summary>
        /// 
        /// </summary>
        public MonitorConfigModel Config
        {
            get { return _config; }
            set { Set(ref _config, value); }
        }

        private ObservableCollection<AreaModel> _areas = new ObservableCollection<AreaModel>();
        /// <summary>
        /// 查询区域下拉列表
        /// </summary>
        public ObservableCollection<AreaModel> Areas
        {
            get { return _areas; }
            set { Set(ref _areas, value); }
        }

        private ObservableCollection<DynamicColumnModel> _lstDynamicColumn = new ObservableCollection<DynamicColumnModel>();

        public ObservableCollection<DynamicColumnModel> LstDynamicColumn
        {
            get { return _lstDynamicColumn; }
            set { Set(ref _lstDynamicColumn, value); }
        }

        #endregion

        #region Commands
        public RelayCommand GetCommand { get; set; }
        public RelayCommand SetCommand { get; set; }
        public RelayCommand MonitorCommand { get; set; }
        public RelayCommand<AreaModel> AreaChangedCommand { get; set; }
        public RelayCommand<object> ShowCodeViewCommand { get; set; }

        #endregion

        public InquiryViewModel()
        {
            GetCommand = new RelayCommand(OnGet);
            SetCommand = new RelayCommand(OnSet);
            MonitorCommand = new RelayCommand(OnMonitor);
            AreaChangedCommand = new RelayCommand<AreaModel>(OnAreaChanged);
            ShowCodeViewCommand = new RelayCommand<object>(OnShowCodeView);
        }

        public void Initialize()
        {
            Areas.Clear();
            Areas.Add(new AreaModel() { Area = "EPC", IsChecked = false, AreaIndex = 1 });
            Areas.Add(new AreaModel() { Area = "TID", IsChecked = false, AreaIndex = 2 });
            Areas.Add(new AreaModel() { Area = "User", IsChecked = false, AreaIndex = 3 });
            OnGet();
        }

        private void OnGet()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            if (IsMonitor) return;
            try
            {
                Task.Run(() =>
                {
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始获取参数!" : "Begin Gettings!");
                    string tip;
                    CurrentReader.CurrentDevice.InitDevice(out tip);
                    if (tip == "")
                    {
                        Application.Current.Dispatcher.Invoke(() =>
                        {
                            Config.Copy(CurrentReader.CurrentDevice);
                            Areas.ToList().ForEach(e => e.IsChecked = false);
                            Areas[Config.AreaIndex - 1].IsChecked = true;
                            SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "获取成功!" : "Gettings Sucessful!");
                        });
                    }
                    else
                    {
                        SetTips(EnumMessage.WARN, tip);
                    }
                });
            }
            catch (Exception ex)
            {
                SetTips(EnumMessage.ERROR, ex.Message);
            }
        }

        private void OnSet()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            if (IsMonitor) return;
            try
            {
                Task.Run(() =>
                {
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始设置参数!" : "Begin Settings!");
                    CurrentReader.CurrentDevice.Copy(Config);
                    string tip;
                    CurrentReader.CurrentDevice.SetDevice(out tip);
                    if (tip == "")
                    {
                        CurrentReader.CurrentDevice.InitDevice(out tip);
                        Application.Current.Dispatcher.Invoke(() =>
                        {
                            Config.Copy(CurrentReader.CurrentDevice);
                            SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "设置成功!" : "Settings Sucessful!");
                        });
                    }
                    else
                    {
                        SetTips(EnumMessage.WARN, tip);
                    }
                });
            }
            catch (Exception ex)
            {
                SetTips(EnumMessage.ERROR, ex.Message);
            }
        }

        /// <summary>
        /// 开始/停止 监控
        /// </summary>
        private void OnMonitor()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            IsMonitor = !IsMonitor;
            if (IsMonitor)
            {
                Config.Copy(CurrentReader.CurrentDevice);
                Areas.ToList().ForEach(e => e.IsChecked = false);
                Areas[Config.AreaIndex - 1].IsChecked = true;
                firstStop = true;
                TotalCount = 0;
                RecognitionSpeed = 0;
                CumulativeBack = 0;
                MonitorDtl.Clear();
                SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始询查" : "Begin Monitor");
                Task.Run(() =>
                {
                    OnStartMonitor();
                });
            }
            else
            {
                SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "停止询查" : "Stop Monitor");
                OnStopMonitor();
            }
        }

        private void OnStartMonitor()
        {
            try
            {
                if (CurrentReader.CurrentReader.m_iState == 0) return;
                if (!IsMonitor) return;

                m_iInvStartTick = Environment.TickCount;
                m_RecognitionSpeed = 1;
                m_second = 0;
                m_isRenew = false;

                if (CurrentReader.CurrentDevice.WorkmodeIndex == 0)
                {
                    if (firstStop)
                    {
                        try
                        {
                            CurrentReader.CurrentReader.ISO.InventoryStop(10000);
                            firstStop = false;
                        }
                        catch (Exception ex) { }
                    }
                    if (CurrentReader.CurrentDevice.IsAnswerStop1 && CurrentReader.CurrentDevice.MS != "0")
                    {
                        uint param;
                        uint.TryParse(CurrentReader.CurrentDevice.MS.ToString(), out param);
                        CurrentReader.CurrentReader.ISO.Inventory(0, param);
                    }
                    else if (CurrentReader.CurrentDevice.IsAnswerStop2)
                    {
                        uint param;
                        uint.TryParse(CurrentReader.CurrentDevice.InventoryRounds.ToString(), out param);
                        CurrentReader.CurrentReader.ISO.Inventory(1, param);
                    }
                    else
                    {
                        CurrentReader.CurrentReader.ISO.Inventory(0, 0);
                    }
                }

                Task.Run(() =>
                {
                    while (IsMonitor)
                    {
                        StartMonitor();
                    }
                });
            }
            catch (Exception ex)
            {
                if (ex is ReaderException && (((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_COMM_TIMEOUT ||
                           ((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_RESP_FORMAT_ERROR || ((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_COMM_READ_FAILED))
                {
                    Thread.Sleep(1000);
                    OnStartMonitor();
                }
                else
                    SetTips(EnumMessage.ERROR, ex.Message);
            }
        }

        /// <summary>
        /// 开始监控
        /// </summary>
        private void StartMonitor()
        {
            try
            {
                TagItem item = CurrentReader.CurrentReader.ISO.GetTagUii(1000);
                if (item == null)
                {
                    if (CurrentReader.CurrentDevice.IsAnswerStop2 || (CurrentReader.CurrentDevice.IsAnswerStop1 && CurrentReader.CurrentDevice.MS != "0"))
                    {
                        Application.Current.Dispatcher.Invoke(() =>
                        {
                            IsMonitor = false;
                            OnStopMonitor();
                        });
                    }
                    return;
                }
                if (item.Antenna == 0) return;

                ShowTagItem sitem = new ShowTagItem(item);
                MonitorDataDtlModel dtl = MonitorDtl.ToList().Find(e => e.Code == item.Code.HexArray2String());
                if (dtl == null)
                {
                    string[] m_data = new string[] { "0", "0", "0", "0", "0", "0", "0", "0" };
                    if (item.Antenna > 0 && item.Antenna <= m_data.Length)
                        m_data[item.Antenna - 1] = (m_data[item.Antenna - 1].Obj2Int() + 1).Obj2String();

                    Application.Current.Dispatcher.Invoke(() =>
                    {
                        MonitorDtl.Add(new MonitorDataDtlModel()
                        {
                            AreaIndex = CurrentReader.CurrentDevice.AreaIndex,
                            Code = item.Code.HexArray2String(),
                            DataLen = item.LEN,
                            AntCount = string.Join('/', m_data),
                            RSSI = item.Rssi / 10,
                            Channel = item.Channel
                        });
                    });
                }
                else
                {
                    string[] m_data = dtl.AntCount.Split('/');
                    if (item.Antenna > 0 && item.Antenna <= m_data.Length)
                        m_data[item.Antenna - 1] = (m_data[item.Antenna - 1].Obj2Int() + 1).Obj2String();

                    dtl.Code = item.Code.HexArray2String();
                    dtl.DataLen = item.LEN;
                    dtl.AntCount = string.Join('/', m_data);
                    dtl.RSSI = item.Rssi / 10;
                    dtl.Channel = item.Channel;
                }

                int nowTime = Environment.TickCount;
                if ((nowTime - m_iInvStartTick) / 1000 != m_second)
                {
                    m_isRenew = true;
                    m_second = (nowTime - m_iInvStartTick) / 1000;
                }
                m_RecognitionSpeed++;
                TotalCount = MonitorDtl.Count;
                CumulativeBack = CumulativeBack + 1;
                if (m_isRenew)
                {
                    RecognitionSpeed = m_RecognitionSpeed;//(monitor.CumulativeBack * 1000.0f / (nowTime - m_iInvStartTick + 1)).ToString("N0").Obj2Int();
                    m_RecognitionSpeed = 0;
                    m_isRenew = false;
                }
            }
            catch (Exception ex)
            {
                if (ex is ReaderException && (((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_COMM_TIMEOUT ||
                            ((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_RESP_FORMAT_ERROR || ((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_COMM_READ_FAILED
                            || ((ReaderException)ex).ErrorCode == ReaderException.ERROR_DLL_DISCONNECT))
                {
                    if (CurrentReader.CurrentDevice.IsAnswerStop2 || (CurrentReader.CurrentDevice.IsAnswerStop1 && CurrentReader.CurrentDevice.MS != "0"))
                    {
                        Application.Current.Dispatcher.Invoke(() =>
                        {
                            IsMonitor = false;
                            OnStopMonitor();
                        });
                    }
                }
                else
                {
                    Application.Current.Dispatcher.Invoke(() =>
                    {
                        IsMonitor = false;
                        OnStopMonitor();
                    });
                    SetTips(EnumMessage.ERROR, ex.Message);
                }
            }
        }

        /// <summary>
        /// 停止监控
        /// </summary>
        private void OnStopMonitor()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            stopCount = 0;
            IsMonitor = false;
            StopMonitor();
        }

        private void StopMonitor()
        {
            try
            {
                if (stopCount > 10) return;
                CurrentReader.CurrentReader.ISO.InventoryStop(10000);
            }
            catch (Exception ex)
            {
                stopCount++;
                StopMonitor();
                SetTips(EnumMessage.ERROR, ex.Message);
            }
        }

        private void OnAreaChanged(AreaModel model)
        {
            Areas.ToList().ForEach(e => e.IsChecked = false);
            Config.Area = model.Area;
            Config.AreaIndex = model.AreaIndex;
            model.IsChecked = true;
        }

        private void OnShowCodeView(object o)
        {
            if (IsMonitor) return;

            MonitorDataDtlModel model = (MonitorDataDtlModel)o;
            if (ActionManager.ExecuteAndResult("UpdateEpcDialog", new UpdateEpcDialogViewModel(this) { OldCode = model.EPC, NewCode = model.EPC }))
            {
                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "修改成功！" : "Successfully modified!" });
                model.Code = ModifyCode;
            }
        }

        /// <summary>
        /// 按钮点击改变事件
        /// </summary>
        private void SetButtonStyle()
        {
            if (IsMonitor)
            {
                ButtonText = "STOP";
                ButtonIcon = "\ue61b";
            }
            else
            {
                ButtonText = "START";
                ButtonIcon = "\ue602";
            }
        }
    }
}
