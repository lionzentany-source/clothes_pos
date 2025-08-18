using GalaSoft.MvvmLight.Command;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO.Ports;
using System.Linq;
using System.Reflection;
using System.Reflection.PortableExecutable;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Threading;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class MainWindowViewModel : BaseViewModel
    {
        #region Properties

        public List<MenuModel> Menus { get; set; }

        public string Version
        {
            get { return GlobalModel.Version; }
        }

        private string _language = "CN";

        public string Language
        {
            get { return _language; }
            set { Set(ref _language, value); }
        }

        private object _viewContent;
        /// <summary>
        /// 视图
        /// </summary>
        public object ViewContent
        {
            get { return _viewContent; }
            set { Set(ref _viewContent, value); }
        }

        private bool _isConnect = false;

        public bool IsConnect
        {
            get { return _isConnect; }
            set
            {
                Set(ref _isConnect, value);
                ConnectIcon = _isConnect ? "\ue619" : "\ue681";
                ConnectText = _isConnect ? GlobalModel.IsChinese ? "断开连接" : "DisConnect Reader" : GlobalModel.IsChinese ? "连接读卡器" : "Connect Reader";
            }
        }

        private bool _isLoading = false;

        public bool IsLoading
        {
            get { return _isLoading; }
            set { Set(ref _isLoading, value); }
        }

        private ObservableCollection<string> _USBItems = new ObservableCollection<string>();

        public ObservableCollection<string> USBItems
        {
            get { return _USBItems; }
            set { Set(ref _USBItems, value); }
        }

        private int _itemIndex;

        public int ItemIndex
        {
            get { return _itemIndex; }
            set { Set(ref _itemIndex, value); }
        }

        private string _connectIcon = "\ue681";

        public string ConnectIcon
        {
            get { return _connectIcon; }
            set { Set(ref _connectIcon, value); }
        }

        private string _connectText = GlobalModel.IsChinese ? "连接读卡器" : "Connect Reader";

        public string ConnectText
        {
            get { return _connectText; }
            set { Set(ref _connectText, value); }
        }

        private string _COMPort;

        public string COMPort
        {
            get { return _COMPort; }
            set { Set(ref _COMPort, value); }
        }

        private int _COMBaudIndex;

        public int COMBaudIndex
        {
            get { return _COMBaudIndex; }
            set { Set(ref _COMBaudIndex, value); }
        }

        private ObservableCollection<string> _COMItems = new ObservableCollection<string>();

        public ObservableCollection<string> COMItems
        {
            get { return _COMItems; }
            set { Set(ref _COMItems, value); }
        }

        #endregion

        #region Commands

        public RelayCommand<object> MinCommand { get => new RelayCommand<object>(o => OnMin(o)); }
        public RelayCommand<object> MaxCommand { get => new RelayCommand<object>(o => OnMax(o)); }
        public RelayCommand<object> CloseCommand { get => new RelayCommand<object>(o => OnClose(o)); }
        public RelayCommand LanguageChangedCommand { get; set; }
        public RelayCommand<object> SwitchPageCommand { get; set; }
        public RelayCommand RefreshCommand { get; set; }
        public RelayCommand ScanCommand { get; set; }
        public RelayCommand COMConnectCommand { get; set; }
        public RelayCommand USBConnectCommand { get; set; }
        public RelayCommand ConnectChangedCommand { get; set; }

        #endregion

        public MainWindowViewModel()
        {
            if (!IsInDesignMode)
            {
                Menus = new List<MenuModel>();
                Menus.Add(new MenuModel { IsSelected = true, MenuHeader = GlobalModel.IsChinese ? "询查" : "Inquiry", MenuIcon = "\ue88e", TargetView = "InquiryView" });
                Menus.Add(new MenuModel { IsSelected = false, MenuHeader = GlobalModel.IsChinese ? "读写" : "Read-Write", MenuIcon = "\ue8cf", TargetView = "ReadWriteView" });
                Menus.Add(new MenuModel { IsSelected = false, MenuHeader = GlobalModel.IsChinese ? "设置" : "Config", MenuIcon = "\ue9cb", TargetView = "SetUpView" });

                OnSwitchPage(Menus[0]);
            }

            LanguageChangedCommand = new RelayCommand(OnLanguageChanged);
            SwitchPageCommand = new RelayCommand<object>(OnSwitchPage);
            RefreshCommand = new RelayCommand(OnRefresh);
            ScanCommand = new RelayCommand(OnScan);
            COMConnectCommand = new RelayCommand(OnCOMConnect);
            USBConnectCommand = new RelayCommand(OnUSBConnect);
            ConnectChangedCommand = new RelayCommand(OnConnectChanged);

            if (!GlobalModel.IsChinese)
            {
                ResourceDictionary resourceDictionary = Application.Current.Resources.MergedDictionaries.FirstOrDefault(d => d.Source.OriginalString.Equals(@"\Assets\Languages\en-us.xaml"));
                Application.Current.Resources.MergedDictionaries.Remove(resourceDictionary);
                Application.Current.Resources.MergedDictionaries.Add(resourceDictionary);
                Language = "EN";
            }

            OnRefresh();
            COMBaudIndex = 4;
            OnScan();
        }

        private void OnLanguageChanged()
        {
            try
            {
                List<ResourceDictionary> dictionaryList = new List<ResourceDictionary>();
                foreach (ResourceDictionary dictionary in Application.Current.Resources.MergedDictionaries)
                {
                    if (dictionary.Source == null) continue;
                    dictionaryList.Add(dictionary);
                }
                string requestedCulture = !GlobalModel.IsChinese ? @"\Assets\Languages\zh-cn.xaml" : @"\Assets\Languages\en-us.xaml";
                ResourceDictionary resourceDictionary = dictionaryList.FirstOrDefault(d => d.Source.OriginalString.Equals(requestedCulture));
                Application.Current.Resources.MergedDictionaries.Remove(resourceDictionary);
                Application.Current.Resources.MergedDictionaries.Add(resourceDictionary);
                string language = !GlobalModel.IsChinese ? "zh-cn" : "en-us";
                ConfigurationExtend.UpdateAppConfig("language", language);
                Language = GlobalModel.IsChinese ? "CN" : "EN";
            }
            catch (Exception ex)
            {
            }
        }

        /// <summary>
        /// 菜单栏改变事件
        /// </summary>
        /// <param name="o"></param>
        private void OnSwitchPage(object o)
        {
            var model = o as MenuModel;
            if (model != null)
            {
                if (ViewContent != null && ViewContent.GetType().Name == model.TargetView) return;
                if (ViewContent != null && ViewContent.GetType().Name == "InquiryView")
                {
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "停止询查" : "Stop Monitor");
                    ActionManager.Execute("OnStopMonitor");
                }
                if (ViewContent != null && ViewContent.GetType().Name == "SetUpView")
                {
                    ActionManager.Execute("OnBack");
                }
                Type type = Assembly.Load("UHF_Desk").GetType("UHF_Desk." + model.TargetView)!;
                ViewContent = Activator.CreateInstance(type)!;
            }
        }

        private void OnRefresh()
        {
            COMItems.Clear();
            string[] prots = SerialPort.GetPortNames();
            foreach (var item in prots)
            {
                COMItems.Add(item);
            }
        }

        private void OnScan()
        {
            string strSN;
            byte[] arrBuffer = new byte[256];
            string flag;
            int iHidNumber;
            ushort iIndex;
            USBItems.Clear();
            iHidNumber = new NetReader() { IsChinese = GlobalModel.IsChinese }.GetUsbCount();
            for (iIndex = 0; iIndex < iHidNumber; iIndex++)
            {
                new NetReader() { IsChinese = GlobalModel.IsChinese }.GetUsbInfo(iIndex, arrBuffer);
                strSN = System.Text.Encoding.Default.GetString(arrBuffer).Replace("\0", "");
                flag = strSN.Substring(strSN.Length - 3);
                if (flag.ToLower() == "kbd")
                {
                    USBItems.Add("\\Keyboard-can'topen");
                }
                else
                {
                    USBItems.Add("\\USB-open");
                }
                arrBuffer = new byte[256];
            }
            if (iHidNumber > 0)
                ItemIndex = 0;
        }

        private void OnCOMConnect()
        {
            try
            {
                if (string.IsNullOrEmpty(COMPort))
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请先选择串口" : "Please select a serial port first" });
                    return;
                }
                if (COMBaudIndex < 0)
                {
                    return;
                }

                Task.Run(() =>
                {
                    try
                    {
                        if (!CurrentReader.Open(COMPort, (byte)COMBaudIndex))
                        {
                            Application.Current.Dispatcher.Invoke(() =>
                            {
                                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "仅支持连接[Desk Reader]，请确认！" : "Only supports connecting to [Desk Reader], please confirm!" });
                            });
                        }
                        else
                        {
                            HardwareVersion = CurrentReader.HardwareVersion;
                            FirmwareVersion = CurrentReader.FirmwareVersion;
                            DeviceSN = CurrentReader.DeviceSN;

                            Application.Current.Dispatcher.Invoke(() =>
                            {
                                ViewContent = null;
                                OnSwitchPage(Menus[0]);
                            });
                            IsConnect = true;
                            IsLoading = false;
                        }
                    }
                    catch (Exception ex)
                    {
                        CurrentReader.CloseReader();
                        Application.Current.Dispatcher.Invoke(() =>
                        {
                            ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = ex.Message.ToString() });
                        });
                    }
                });
            }
            catch (Exception ex)
            {
                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = ex.Message.ToString() });
            }
        }

        private void OnUSBConnect()
        {
            try
            {
                if (USBItems[ItemIndex] == "\\Keyboard-can'topen")
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请选择正确的USB选项[\\USB-open]" : "Please select the correct USB option[\\USB-open]" });
                    return;
                }
                if (ItemIndex < 0)
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "请先选择连接的USB" : "Please select the connected USB first" });
                    return;
                }

                Task.Run(() =>
                {
                    try
                    {
                        if (!CurrentReader.Open((ushort)ItemIndex))
                        {
                            Application.Current.Dispatcher.Invoke(() =>
                            {
                                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "仅支持连接[Desk Reader]，请确认！" : "Only supports connecting to [Desk Reader], please confirm!" });
                            });
                        }
                        else
                        {
                            HardwareVersion = CurrentReader.HardwareVersion;
                            FirmwareVersion = CurrentReader.FirmwareVersion;
                            DeviceSN = CurrentReader.DeviceSN;

                            Application.Current.Dispatcher.Invoke(() =>
                            {
                                ViewContent = null;
                                OnSwitchPage(Menus[0]);
                            });
                            IsConnect = true;
                            IsLoading = false;
                        }
                    }
                    catch (Exception ex)
                    {
                        CurrentReader.CloseReader();
                        Application.Current.Dispatcher.Invoke(() =>
                        {
                            ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = ex.Message.ToString() });
                        });
                    }
                });
            }
            catch (Exception ex)
            {
                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = ex.Message.ToString() });
            }
        }

        private void OnConnectChanged()
        {
            if (IsConnect)
            {
                if (CurrentReader != null)
                    CurrentReader.CloseReader();
                CurrentReader = new ReaderModel(new NetReader() { IsChinese = GlobalModel.IsChinese });
                OnSwitchPage(Menus[0]);
                Menus[0].IsSelected = true;
                IsConnect = false;
                ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "消息提醒" : "INFO", Message = GlobalModel.IsChinese ? "断开连接成功！" : "Successfully disconnected!" });
            }
            else
                IsLoading = !IsLoading;
        }
    }
}
