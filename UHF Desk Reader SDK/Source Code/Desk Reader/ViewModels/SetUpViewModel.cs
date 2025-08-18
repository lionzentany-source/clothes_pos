using GalaSoft.MvvmLight.Command;
using System;
using System.Windows;
using System.Windows.Media;

namespace UHF_Desk
{
    public class SetUpViewModel : BaseViewModel
    {
        #region Fields

        string color = "#008000";

        #endregion

        #region Properties

        private DeviceConfigModel _device = new DeviceConfigModel();
        /// <summary>
        /// 
        /// </summary>
        public DeviceConfigModel Device
        {
            get { return _device; }
            set { Set(ref _device, value); }
        }

        private SolidColorBrush _foreground;

        public SolidColorBrush Foreground
        {
            get { return _foreground; }
            set { Set(ref _foreground, value); }
        }

        #endregion

        #region Commands

        public RelayCommand GetCommand { get; set; }
        public RelayCommand SetCommand { get; set; }
        public RelayCommand InitializationCommand { get; set; }

        #endregion

        public SetUpViewModel()
        {
            GetCommand = new RelayCommand(OnGet);
            SetCommand = new RelayCommand(OnSet);
            InitializationCommand = new RelayCommand(OnInitialization);
        }

        public void Initialize()
        {
            OnGet();
        }

        private void OnGet()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            try
            {
                SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始获取参数!" : "Begin Getting!");
                string tip;
                CurrentReader.CurrentDevice.InitDevice(out tip);
                if (tip == "")
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "获取成功!" : "Gettings Sucessful!");
                else
                    SetTips(EnumMessage.WARN, tip);
                Device.Copy(CurrentReader.CurrentDevice);
            }
            catch (Exception ex)
            {
                SetTips(EnumMessage.ERROR, GlobalModel.IsChinese ? "参数获取失败!" : "Parameter Getting Failed!");
            }
        }

        private void OnSet()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            try
            {
                SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始设置参数!" : "Begin Setting!");
                CurrentReader.CurrentDevice.Copy(Device);
                string tip;
                CurrentReader.CurrentDevice.SetDevice(out tip);
                if (tip == "")
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "设置成功!" : "Settings Sucessful!");
                else
                    SetTips(EnumMessage.WARN, tip);
            }
            catch (Exception ex)
            {
                SetTips(EnumMessage.ERROR, GlobalModel.IsChinese ? "参数设置失败!" : "Parameter Setting Failed!");
            }
        }

        private void OnInitialization()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            try
            {
                SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始初始化" : "Begin Initialization!");
                CurrentReader.CurrentReader.RebootDevice();
                SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "初始化成功!" : "Initialization Sucessful!");
                SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "开始获取参数!" : "Begin Getting!");
                string tip;
                CurrentReader.CurrentDevice.InitDevice(out tip);
                if (tip == "")
                    SetTips(EnumMessage.INFO, GlobalModel.IsChinese ? "获取成功!" : "Gettings Sucessful!");
                else
                    SetTips(EnumMessage.WARN, tip);
                Device.Copy(CurrentReader.CurrentDevice);
            }
            catch (Exception ex)
            {
                SetTips(EnumMessage.ERROR, GlobalModel.IsChinese ? "初始化失败!" : "Initialization Failed!");
            }
        }

        private void OnBack()
        {
            if (CurrentReader.CurrentReader.m_iState == 0) return;
            try
            {
                if (CurrentReader.CurrentDevice.IsChanged)
                {
                    if (ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Message = GlobalModel.IsChinese ? "存在未保存的配置，是否保存并退出？\r\n[确定]保存并退出\r\n[取消]不保存并退出" : "There are unsaved configurations. Do you want to save and exit?\r\n[SURE]Save and Exit\r\n[Cancel]Not Save and Exit", Visual = Visibility.Visible }))
                    {
                        string tip;
                        if (CurrentReader.CurrentDevice.IsChanged) CurrentReader.CurrentDevice.SetDevice(out tip);
                    }
                    else
                    {
                        CurrentReader.CurrentDevice.IsChanged = false;
                    }
                }
            }
            catch (Exception ex)
            {
                Application.Current.Dispatcher.Invoke(() =>
                {
                    ActionManager.ExecuteAndResult("MessageDialog", new MessageModel() { Title = GlobalModel.IsChinese ? "错误提醒" : "ERROR", Message = ex.Message });
                });
            }
        }
    }
}
