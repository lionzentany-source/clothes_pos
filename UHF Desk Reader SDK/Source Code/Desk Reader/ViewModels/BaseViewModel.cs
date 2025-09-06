using GalaSoft.MvvmLight;
using log4net;
using System;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Threading;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class BaseViewModel : ViewModelBase
    {
        #region Fileds

        long _start;
        string _msg;
        ILog infoLog;
        ILog wareLog;
        ILog errorLog;

        #endregion

        #region Properties

        private string _nowTime;

        public string NowTime
        {
            get { return _nowTime; }
            set { Set(ref _nowTime, value); }
        }

        private static LogModel _logs = new LogModel();

        public LogModel Logs
        {
            get { return _logs; }
            set { Set(ref _logs, value); }
        }

        private string _hardwareVersion;
        /// <summary>
        /// 硬件版本
        /// </summary>
        public string HardwareVersion
        {
            get { return _hardwareVersion; }
            set { Set(ref _hardwareVersion, value); }
        }

        private string _firmwareVersion;
        /// <summary>
        /// 软件版本
        /// </summary>
        public string FirmwareVersion
        {
            get { return _firmwareVersion; }
            set { Set(ref _firmwareVersion, value); }
        }

        private string _deviceSN;
        /// <summary>
        /// 设备SN
        /// </summary>
        public string DeviceSN
        {
            get { return _deviceSN; }
            set { Set(ref _deviceSN, value); }
        }

        private int _totalCount = 0;
        /// <summary>
        /// 盘点总数
        /// </summary>
        public int TotalCount
        {
            get { return _totalCount; }
            set { Set(ref _totalCount, value); }
        }

        private int _recognitionSpeed = 0;
        /// <summary>
        /// 识别速度
        /// </summary>
        public int RecognitionSpeed
        {
            get { return _recognitionSpeed; }
            set { Set(ref _recognitionSpeed, value); }
        }

        private int _cumulativeBack = 0;
        /// <summary>
        /// 累计返回
        /// </summary>
        public int CumulativeBack
        {
            get { return _cumulativeBack; }
            set { Set(ref _cumulativeBack, value); }
        }

        private static ObservableCollection<MonitorDataDtlModel> _monitorDtl = new ObservableCollection<MonitorDataDtlModel>();
        public ObservableCollection<MonitorDataDtlModel> MonitorDtl
        {
            get { return _monitorDtl; }
            set { Set(ref _monitorDtl, value); }
        }

        /// <summary>
        /// 当前连接的读卡器
        /// </summary>
        public static ReaderModel CurrentReader { get; set; } = new ReaderModel(new NetReader() { IsChinese = GlobalModel.IsChinese });

        #endregion

        #region Virtual Methods

        /// <summary>
        /// 最小化
        /// </summary>
        /// <param name="o"></param>
        public virtual void OnMin(object o)
        {
            (o as Window).WindowState = WindowState.Minimized;
        }

        /// <summary>
        /// 最大化
        /// </summary>
        /// <param name="o"></param>
        public virtual void OnMax(object o)
        {
            (o as Window).WindowState = (o as Window).WindowState == WindowState.Normal ? WindowState.Maximized : WindowState.Normal;
        }

        /// <summary>
        /// 关闭窗体
        /// </summary>
        /// <param name="o"></param>
        public virtual void OnClose(object o)
        {
            (o as Window).Close();
        }

        public virtual void SetTips(EnumMessage msg, string tip)
        {
            _logs.Tip = DateTime.Now.ToString("yyyy-dd-MM HH:mm:ss") + " ： " + tip;
            switch (msg)
            {
                case EnumMessage.INFO:
                    infoLog.Info(tip); break;
                case EnumMessage.WARN:
                    wareLog.Warn(tip); break;
                case EnumMessage.ERROR:
                    errorLog.Error(tip); break;
                default: break;
            }
        }

        #endregion

        public BaseViewModel()
        {
            DispatcherTimer timer = new DispatcherTimer();
            _start = Environment.TickCount;
            timer.Tick += timer_Tick;
            timer.Interval = new TimeSpan(0, 0, 0, 1, 0);
            timer.Start();

            infoLog = LogManager.GetLogger("InfoLog");
            wareLog = LogManager.GetLogger("WareLog");
            errorLog = LogManager.GetLogger("ErrorLog");
        }

        private void timer_Tick(object sender, EventArgs e)
        {
            Task.Run(() =>
            {
                NowTime = DateTime.Now.ToString("yyyy-dd-MM HH:mm:ss");
            });
        }

    }
}
