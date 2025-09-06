using System.Linq;

namespace UHF_Desk
{
    public class MonitorDataDtlModel : BaseModel
    {
        private string _macaddr;
        /// <summary>
        /// 
        /// </summary>
        public string Macaddr
        {
            get { return _macaddr; }
            set { Set(ref _macaddr, value); }
        }

        private string _code;
        /// <summary>
        /// 编码
        /// </summary>
        public string Code
        {
            get { return _code; }
            set
            {
                Set(ref _code, value);
                SetCode();
            }
        }

        private int _dataLen;
        /// <summary>
        /// 数据长度
        /// </summary>
        public int DataLen
        {
            get { return _dataLen; }
            set { Set(ref _dataLen, value); }
        }

        private string _antCount;
        /// <summary>
        /// 次数（天线1/2/3/4）
        /// </summary>
        public string AntCount
        {
            get { return _antCount; }
            set
            {
                Set(ref _antCount, value);
                SetAnt();
            }
        }

        private int _RSSI;
        /// <summary>
        /// RSSI(dBm)
        /// </summary>
        public int RSSI
        {
            get { return _RSSI; }
            set { Set(ref _RSSI, value); }
        }

        private int _channel;
        /// <summary>
        /// 信道
        /// </summary>
        public int Channel
        {
            get { return _channel; }
            set { Set(ref _channel, value); }
        }

        private bool _isChecked;
        [Ignore(true)]
        public bool IsChecked
        {
            get { return _isChecked; }
            set { Set(ref _isChecked, value); }
        }

        private string _epc = string.Empty;

        public string EPC
        {
            get { return _epc; }
            set { Set(ref _epc, value); }
        }

        private string _tid = string.Empty;

        public string TID
        {
            get { return _tid; }
            set { Set(ref _tid, value); }
        }

        private string _user = string.Empty;

        public string USER
        {
            get { return _user; }
            set { Set(ref _user, value); }
        }

        private int _totalCount;

        public int TotalCount
        {
            get { return _totalCount; }
            set { Set(ref _totalCount, value); }
        }

        private int _ant1;

        public int Ant1
        {
            get { return _ant1; }
            set { Set(ref _ant1, value); }
        }

        private int _ant2;

        public int Ant2
        {
            get { return _ant2; }
            set { Set(ref _ant2, value); }
        }

        private int _ant3;

        public int Ant3
        {
            get { return _ant3; }
            set { Set(ref _ant3, value); }
        }

        private int _ant4;

        public int Ant4
        {
            get { return _ant4; }
            set { Set(ref _ant4, value); }
        }

        private int _ant5;

        public int Ant5
        {
            get { return _ant5; }
            set { Set(ref _ant5, value); }
        }

        private int _ant6;

        public int Ant6
        {
            get { return _ant6; }
            set { Set(ref _ant6, value); }
        }

        private int _ant7;

        public int Ant7
        {
            get { return _ant7; }
            set { Set(ref _ant7, value); }
        }

        private int _ant8;

        public int Ant8
        {
            get { return _ant8; }
            set { Set(ref _ant8, value); }
        }

        private int _areaIndex;

        public int AreaIndex
        {
            get { return _areaIndex; }
            set { Set(ref _areaIndex, value); }
        }

        private void SetCode()
        {
            if (AreaIndex == 1) // EPC
                EPC = Code;
            else if (AreaIndex == 2) // TID
                TID = Code;
            else if (AreaIndex == 3) // USER
                USER = Code;
            else if (AreaIndex == 4) // EPC+TID
            {
                EPC = Code.Substring(0, 36);
                TID = Code.Substring(36);
            }
            else if (AreaIndex == 5) // EPC+USER
            {
                EPC = Code.Substring(0, 36);
                USER = Code.Substring(36);
            }
            else if (AreaIndex == 6) // EPC+TID+USER
            {
                EPC = Code.Substring(0, 36);
                TID = Code.Substring(36, 36);
                USER = Code.Substring(72);
            }
            else
                EPC = Code;
        }

        private void SetAnt()
        {
            if (!string.IsNullOrEmpty(AntCount))
            {
                string[] ants = AntCount.Split('/');
                if (ants.Count() >= 1) Ant1 = ants[0].Obj2Int(0);
                if (ants.Count() >= 2) Ant2 = ants[1].Obj2Int(0);
                if (ants.Count() >= 3) Ant3 = ants[2].Obj2Int(0);
                if (ants.Count() >= 4) Ant4 = ants[3].Obj2Int(0);
                if (ants.Count() >= 5) Ant5 = ants[4].Obj2Int(0);
                if (ants.Count() >= 6) Ant6 = ants[5].Obj2Int(0);
                if (ants.Count() >= 7) Ant7 = ants[6].Obj2Int(0);
                if (ants.Count() >= 8) Ant8 = ants[7].Obj2Int(0);
                TotalCount = Ant1 + Ant2 + Ant3 + Ant4 + Ant5 + Ant6 + Ant7 + Ant8;
            }
        }
    }
}
