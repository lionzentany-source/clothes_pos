using GalaSoft.MvvmLight.Command;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class ReadWriteViewModel : BaseViewModel
    {
        #region Fields

        string code;
        MemBank mem;
        int startAddr;
        int dataLen;
        byte[] password;
        byte[] writeData;
        //  Lock
        byte area;
        byte action;
        byte[] lockpwd;
        // kill
        byte[] killpwd;
        bool IsStopOperation = false;

        #endregion

        #region Properties

        private ObservableCollection<ReadWriteModel> _readWriteData = new ObservableCollection<ReadWriteModel>();

        public ObservableCollection<ReadWriteModel> ReadWriteData
        {
            get { return _readWriteData; }
            set { Set(ref _readWriteData, value); }
        }

        private ObservableCollection<MonitorDataDtlModel> _monitorEpcDtl = new ObservableCollection<MonitorDataDtlModel>();

        public ObservableCollection<MonitorDataDtlModel> MonitorEpcDtl
        {
            get { return _monitorEpcDtl; }
            set { Set(ref _monitorEpcDtl, value); }
        }

        private TagModel _tag = new TagModel();

        public TagModel Tag
        {
            get { return _tag; }
            set { Set(ref _tag, value); }
        }

        private LockTagModel _lockTag = new LockTagModel();

        public LockTagModel LockTag
        {
            get { return _lockTag; }
            set { Set(ref _lockTag, value); }
        }

        private string _readTagText = GlobalModel.IsChinese ? "读标签" : "Read TAG";
        /// <summary>
        /// 按钮文本
        /// </summary>
        public string ReadTagText
        {
            get { return _readTagText; }
            set { Set(ref _readTagText, value); }
        }

        private SolidColorBrush _readTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
        /// <summary>
        /// 按钮前景色
        /// </summary>
        public SolidColorBrush ReadTagBackground
        {
            get { return _readTagBackground; }
            set { Set(ref _readTagBackground, value); }
        }

        private string _writeTagText = GlobalModel.IsChinese ? "写标签" : "Write TAG";
        /// <summary>
        /// 按钮文本
        /// </summary>
        public string WriteTagText
        {
            get { return _writeTagText; }
            set { Set(ref _writeTagText, value); }
        }

        private SolidColorBrush _writeTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
        /// <summary>
        /// 按钮前景色
        /// </summary>
        public SolidColorBrush WriteTagBackground
        {
            get { return _writeTagBackground; }
            set { Set(ref _writeTagBackground, value); }
        }

        private string _lockTagText = GlobalModel.IsChinese ? "锁定标签" : "Lock TAG";
        /// <summary>
        /// 按钮文本
        /// </summary>
        public string LockTagText
        {
            get { return _lockTagText; }
            set { Set(ref _lockTagText, value); }
        }

        private SolidColorBrush _lockTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
        /// <summary>
        /// 按钮前景色
        /// </summary>
        public SolidColorBrush LockTagBackground
        {
            get { return _lockTagBackground; }
            set { Set(ref _lockTagBackground, value); }
        }

        private string _killTagText = GlobalModel.IsChinese ? "灭活标签" : "Kill TAG";
        /// <summary>
        /// 按钮文本
        /// </summary>
        public string KillTagText
        {
            get { return _killTagText; }
            set { Set(ref _killTagText, value); }
        }

        private SolidColorBrush _killTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
        /// <summary>
        /// 按钮前景色
        /// </summary>
        public SolidColorBrush KillTagBackground
        {
            get { return _killTagBackground; }
            set { Set(ref _killTagBackground, value); }
        }

        private bool _isEnabled = true;

        public bool IsEnabled
        {
            get { return _isEnabled; }
            set { Set(ref _isEnabled, value); }
        }

        private int _state;

        public int State
        {
            get { return _state; }
            set
            {
                _state = value;
                SetButtonStyle();
            }
        }

        #endregion

        #region Commands

        public RelayCommand<string> ButtonClickCommand { get; set; }
        public RelayCommand<MonitorDataDtlModel> SelectionChangedCommand { get; set; }
        public RelayCommand ContinuousWriteCommand { get; set; }

        #endregion

        public ReadWriteViewModel()
        {
            SelectionChangedCommand = new RelayCommand<MonitorDataDtlModel>(OnSelectionChanged);
            ButtonClickCommand = new RelayCommand<string>(OnButtonClick);
            ContinuousWriteCommand = new RelayCommand(OnContinuousWrite);
        }

        public void Initialize()
        {
            MonitorEpcDtl = MonitorDtl.Where(m => m.AreaIndex == 1).ToObservableCollection();
        }

        private void OnSelectionChanged(MonitorDataDtlModel model)
        {
            if (model == null) return;
            model.IsChecked = !model.IsChecked;
        }

        private void OnButtonClick(string param)
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            if (IsStopOperation) return;
            if (State > 0)
            {
                State = 0;
                OnStop();
            }
            else
            {
                switch (param)
                {
                    case "Read":
                        if (!Verification(param)) return;
                        State = 1;
                        break;
                    case "Write":
                        if (!Verification(param)) return;
                        State = 2;
                        break;
                    case "Lock":
                        if (!Verification(param)) return;
                        State = 3;
                        break;
                    case "Kill":
                        if (!Verification(param)) return;
                        State = 4;
                        break;
                    default: return;
                }
                ReadWriteData.Clear();

                Task.Run(() =>
                {
                    OnStart();
                });
            }
        }

        /// <summary>
        /// 数据验证
        /// </summary>
        private bool Verification(string param)
        {
            code = MonitorEpcDtl.Where(e => e.IsChecked).FirstOrDefault()?.Code;
            if ((param == "Write" || param == "Lock" || param == "Kill") && string.IsNullOrEmpty(code))
            {
                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请选择要操作的标签。" : "Please select the label to operate." });
                return false;
            }

            if (CurrentReader.CurrentDevice.WorkmodeIndex == 1)
            {
                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "当前模式为主动读卡，无法做任何操作。" : "The current mode is active card reading and no action can be taken." });
                return false;
            }

            if (param == "Read" || param == "Write")
            {
                if (Tag.IsReserve) mem = MemBank.FileType;
                else if (Tag.IsEPC) mem = MemBank.UII;
                else if (Tag.IsTID) mem = MemBank.TID;
                else if (Tag.IsUSER) mem = MemBank.User;
                else
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请选择读写区域。" : "Please select a Read-Write area." });
                    return false;
                }

                startAddr = Tag.StartAddrWORD.Obj2Int();
                if (Tag.StartAddrWORD.Obj2String().Length == 0 || startAddr < 0 || startAddr > 65535)
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "起始地址填写错误，请确认！" : "Starting address filling error. Please confirm!" });
                    return false;
                }

                dataLen = Tag.DataLenWORD.Obj2String().Obj2Int();
                if (Tag.DataLenWORD.Obj2String().Length == 0 || dataLen < 0 || dataLen > 65535)
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "数据长度填写错误，请确认！" : "Data length filling error. Please confirm!" });
                    return false;
                }

                if (Tag.PasswordHEX.Length == 0) password = GlobalModel.EmptyPwd;
                else
                {
                    password = Tag.PasswordHEX.String2HexArray();
                    if (password.Length != 4)
                    {
                        ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "访问密码填写错误，请确认！" : "Access password filling error. Please confirm!" });
                        return false;
                    }
                }
            }

            if (param == "Write")
            {
                writeData = Tag.WriteData.String2HexArray();
                if (Tag.WriteData == null || Tag.WriteData.Length == 0 || writeData.Length == 0)
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请输入写入内容！" : "Please enter the write content!" });
                    return false;
                }
            }

            if (param == "Lock")
            {
                if (LockTag.IsKillPwdArea) area = 0;
                else if (LockTag.IsAccessingPwdArea) area = 1;
                else if (LockTag.IsEPC) area = 2;
                else if (LockTag.IsTID) area = 3;
                else if (LockTag.IsUSER) area = 4;
                else
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请选择锁定区域。" : "Please select a locked area." });
                    return false;
                }

                if (LockTag.IsOpenness) action = 0;
                else if (LockTag.IsPermanentOpenness) action = 1;
                else if (LockTag.IsLock) action = 2;
                else if (LockTag.IsPermanentLock) action = 3;
                else
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请选择锁定状态。" : "Please select a locked State." });
                    return false;
                }

                lockpwd = LockTag.AccessPwdHEX.String2HexArray();
                if (LockTag.AccessPwdHEX.Length == 0 || lockpwd.Length != 4)
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请输入访问口令！" : "Please enter the access password!" });
                    return false;
                }
            }

            if (param == "Kill")
            {
                if (!ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "标签灭活后将彻底毁坏，是否继续灭活标签？" : "After the label is kill, it will be completely destroyed. Do you want to continue kill the label?", Visual = Visibility.Visible }))
                    return false;

                killpwd = LockTag.KillPwdHEX.String2HexArray();
                if (LockTag.KillPwdHEX.Length == 0 || killpwd.Length != 4)
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请输入灭活口令！" : "Please enter the kill password!" });
                    return false;
                }
            }

            return true;
        }

        private void OnStart()
        {
            try
            {
                if (!IsStopOperation && !string.IsNullOrEmpty(code))
                    CurrentReader.CurrentReader.ISO.SetSelectMask(0, (byte)(code.String2HexArray().Length * 8), code.String2HexArray());
                else if (!IsStopOperation)
                    CurrentReader.CurrentReader.ISO.SetSelectMask(0, (byte)0, GlobalModel.EmptyArray);

                if (CurrentReader.ConnectType == "COM") Thread.Sleep(50);
                if (!IsStopOperation && State == 1)
                {
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始读标签" : "Begin Read Tag");
                    CurrentReader.CurrentReader.ISO.ReadTag(password, mem, (ushort)startAddr, (ushort)dataLen);
                }
                else if (!IsStopOperation && State == 2)
                {
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始写标签" : "Begin Write Tag");
                    CurrentReader.CurrentReader.ISO.WriteTag(password, mem, (ushort)startAddr, writeData);
                }
                else if (!IsStopOperation && State == 3)
                {
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始锁标签" : "Begin Lock Tag");
                    CurrentReader.CurrentReader.ISO.LockTag(lockpwd, area, action);
                }
                else if (!IsStopOperation && State == 4)
                {
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始灭活标签" : "Begin Kill Tag");
                    CurrentReader.CurrentReader.ISO.KillTag(killpwd);
                }
                else if (IsStopOperation) return;
                else
                {
                    State = 0;
                    OnStop();
                }

                Task.Run(async () =>
                {
                    while (State > 0)
                    {
                        // 处理刷新频率
                        // await Task.Delay(8);
                        Start();
                    }
                });
            }
            catch (Exception ex)
            {
                Application.Current.Dispatcher.Invoke(() =>
                {
                    State = 0;
                    OnStop();
                    SetTips(EnumMessage.ERROR, ex.Message);
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "错误提醒" : "ERROR", Message = ex.Message });
                });
            }
        }

        private void Start()
        {
            try
            {
                byte btWordsCount = 0;
                byte[] arrData = new byte[256];
                TagRespItem item = null;
                if (!IsStopOperation && State == 1)
                    item = CurrentReader.CurrentReader.ISO.GetReadResp(out btWordsCount, arrData, 1000);
                else if (!IsStopOperation && State == 2)
                    item = CurrentReader.CurrentReader.ISO.GetWriteResp(1000);
                else if (!IsStopOperation && State == 3)
                    item = CurrentReader.CurrentReader.ISO.GetLockResp(1000);
                else if (!IsStopOperation && State == 4)
                    item = CurrentReader.CurrentReader.ISO.GetKillResp(1000);

                // 为空 表示周围没有标签或者指令结束
                if (item == null)
                {
                    Application.Current.Dispatcher.Invoke(() =>
                    {
                        State = 0;
                        SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "结束标签操作" : "End label operation");
                        OnStop();
                    });
                    return;
                }

                Application.Current.Dispatcher.Invoke(() =>
                {
                    byte[] m_data;
                    if (btWordsCount > 0)
                    {
                        m_data = new byte[btWordsCount << 1];
                        Array.Copy(arrData, m_data, m_data.Length);
                    }
                    else
                        m_data = GlobalModel.EmptyArray;

                    ReadWriteModel rw = ReadWriteData.ToList().Find(e => e.Code == item.Code.HexArray2String());
                    if (rw == null)
                    {
                        ReadWriteData.Add(new ReadWriteModel
                        {
                            RespType = 1,
                            TagStatus = item.TagStatus,
                            PC = item.PC.HexArray2String(),
                            Ant = item.Antenna.Obj2String(),
                            CRC = item.CRC.HexArray2String(),
                            Code = item.Code.HexArray2String(),
                            Date = m_data.HexArray2String(),
                            DataLen = m_data.Length >> 1,
                            Number = 1
                        });
                    }
                    else
                    {
                        rw.Number++;
                        rw.TagStatus = item.TagStatus;
                        rw.PC = item.PC.HexArray2String();
                        rw.Ant = item.Antenna.Obj2String();
                        rw.CRC = item.CRC.HexArray2String();
                        rw.Date = m_data.HexArray2String();
                        rw.DataLen = m_data.Length >> 1;
                    }
                    if (State == 1)
                        Tag.WriteData = m_data.HexArray2String();

                    MonitorDataDtlModel dtl = MonitorEpcDtl.ToList().Find(e => e.Code == item.Code.HexArray2String());
                    if (dtl == null)
                    {
                        MonitorEpcDtl.ToList().ForEach(m => m.IsChecked = false);
                        MonitorEpcDtl.Add(new MonitorDataDtlModel() { IsChecked = true, Code = item.Code.HexArray2String() });
                    }
                    else if (State == 2)
                        dtl.IsChecked = false;
                    else
                        dtl.IsChecked = true;
                });
            }
            catch (Exception ex)
            {
                SetTips(EnumMessage.ERROR, GlobalModel.IsChinese ? "阅读器执行命令失败" : "Reader failed to execute command");
                if (ex is ReaderException && (((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_TAG_RESP_TIMEOUT ||
                    ((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_RESP_FORMAT_ERROR))
                { }
                else
                {
                    Application.Current.Dispatcher.Invoke(() =>
                    {
                        State = 0;
                        OnStop();
                    });
                }
            }
        }

        private void OnStop()
        {
            try
            {
                if (CurrentReader.CurrentReader.m_iState == 0) return;
                IsStopOperation = true;
                CurrentReader.CurrentReader.ISO.InventoryStop(10000);
                IsStopOperation = false;
            }
            catch (Exception ex)
            {
                SetTips(EnumMessage.ERROR, ex.Message);
                IsStopOperation = false;
            }
        }

        private void OnContinuousWrite()
        {
            if (CurrentReader.CurrentDevice.WorkmodeIndex == 1) return;
            ActionManager.ExecuteAndResult("ContinuousWriteDialog", new ContinuousWriteDialogViewModel() { Tag = Tag });
        }

        /// <summary>
        /// 按钮点击改变事件
        /// </summary>
        private void SetButtonStyle()
        {
            if (State == 1)
            {
                ReadTagText = GlobalModel.IsChinese ? "停止读" : "STOP Read";
                ReadTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#FF0000"));
                IsEnabled = false;
            }
            else if (State == 2)
            {
                WriteTagText = GlobalModel.IsChinese ? "停止写" : "STOP Write";
                WriteTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#FF0000"));
                IsEnabled = false;
            }
            else if (State == 3)
            {
                LockTagText = GlobalModel.IsChinese ? "停止锁定" : "STOP Lock";
                LockTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#FF0000"));
                IsEnabled = false;
            }
            else if (State == 4)
            {
                KillTagText = GlobalModel.IsChinese ? "停止灭活" : "STOP Kill";
                KillTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#FF0000"));
                IsEnabled = false;
            }
            else
            {
                ReadTagText = GlobalModel.IsChinese ? "读标签" : "Read TAG";
                ReadTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
                WriteTagText = GlobalModel.IsChinese ? "写标签" : "Write TAG";
                WriteTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
                LockTagText = GlobalModel.IsChinese ? "锁定标签" : "Lock TAG";
                LockTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
                KillTagText = GlobalModel.IsChinese ? "灭活标签" : "Kill TAG";
                KillTagBackground = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#4682B4"));
                IsEnabled = true;
            }
        }
    }
}
