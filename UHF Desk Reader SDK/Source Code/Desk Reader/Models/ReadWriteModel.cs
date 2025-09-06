namespace UHF_Desk
{
    public class ReadWriteModel : BaseModel
    {
        private byte _respType;
        /// <summary>
        /// 响应类型，
        /// 1：读标签响应；
		/// 2：写标签响应；
		/// 3：擦除标签响应；
		/// 4：锁定标签响应；
		/// 5：灭活标签响应；
        /// </summary>
        public byte RespType
        {
            get { return _respType; }
            set { Set(ref _respType, value); }
        }

        private byte _tagStatus;
        /// <summary>
        /// 标签状态
        /// </summary>
        public byte TagStatus
        {
            get { return _tagStatus; }
            set { Set(ref _tagStatus, value); }
        }

        private string _pc;

        public string PC
        {
            get { return _pc; }
            set { Set(ref _pc, value); }
        }

        private string _crc;

        public string CRC
        {
            get { return _crc; }
            set { Set(ref _crc, value); }
        }

        private string _code;

        public string Code
        {
            get { return _code; }
            set { Set(ref _code, value); }
        }

        private int _dataLen;

        public int DataLen
        {
            get { return _dataLen; }
            set { Set(ref _dataLen, value); }
        }

        private string _date;

        public string Date
        {
            get { return _date; }
            set { Set(ref _date, value); }
        }

        private string _ant;

        public string Ant
        {
            get { return _ant; }
            set { Set(ref _ant, value); }
        }

        private int _number;

        public int Number
        {
            get { return _number; }
            set { Set(ref _number, value); }
        }
    }
}
