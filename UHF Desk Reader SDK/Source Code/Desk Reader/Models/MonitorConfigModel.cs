namespace UHF_Desk
{
    /// <summary>
    /// 监控界面的配置实体
    /// </summary>
    public class MonitorConfigModel : BaseModel
    {

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
                    MS = 0;
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

        private int _ms;
        /// <summary>
        /// 
        /// </summary>
        public int MS
        {
            get { return _ms; }
            set { Set(ref _ms, value); }
        }

        private int _inventoryRounds;
        /// <summary>
        /// 
        /// </summary>
        public int InventoryRounds
        {
            get { return _inventoryRounds; }
            set { Set(ref _inventoryRounds, value); }
        }

        private int _triggletime;
        /// <summary>
        /// 触发时间
        /// </summary>
        public int Triggletime
        {
            get { return _triggletime; }
            set { Set(ref _triggletime, value); }
        }

        private string _area;

        public string Area
        {
            get { return _area; }
            set { Set(ref _area, value); }
        }

        private int _areaIndex;

        public int AreaIndex
        {
            get { return _areaIndex; }
            set { Set(ref _areaIndex, value); }
        }

        private int _intenelTime;

        public int IntenelTime
        {
            get { return _intenelTime; }
            set
            {
                if (value > 25) value = 25;
                Set(ref _intenelTime, value);
            }
        }

        private int _startaddr;

        public int Startaddr
        {
            get { return _startaddr; }
            set { Set(ref _startaddr, value); }
        }

        private int _dataLen;

        public int DataLen
        {
            get { return _dataLen; }
            set { Set(ref _dataLen, value); }
        }

        private int _filtertime;

        public int Filtertime
        {
            get { return _filtertime; }
            set
            {
                if (value > 255) value = 255;
                Set(ref _filtertime, value);
            }
        }

        private int _WorkmodeIndex;

        public int WorkmodeIndex
        {
            get { return _WorkmodeIndex; }
            set { Set(ref _WorkmodeIndex, value); }
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
    }
}
