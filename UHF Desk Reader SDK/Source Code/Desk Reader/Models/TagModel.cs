namespace UHF_Desk
{
    public class TagModel : BaseModel
    {
        private bool _isReserve;

        public bool IsReserve
        {
            get { return _isReserve; }
            set { Set(ref _isReserve, value); }
        }

        private bool _isEPC = true;

        public bool IsEPC
        {
            get { return _isEPC; }
            set { Set(ref _isEPC, value); }
        }

        private bool _isTID;

        public bool IsTID
        {
            get { return _isTID; }
            set { Set(ref _isTID, value); }
        }

        private bool _isUSER;

        public bool IsUSER
        {
            get { return _isUSER; }
            set { Set(ref _isUSER, value); }
        }

        private string _passwordHEX = "00 00 00 00";

        public string PasswordHEX
        {
            get { return _passwordHEX; }
            set
            {
                value = value.FormatHexString();
                if (value.String2HexArray().Length > 4) return;
                Set(ref _passwordHEX, value);
            }
        }

        private int _startAddrWORD = 2;

        public int StartAddrWORD
        {
            get { return _startAddrWORD; }
            set { Set(ref _startAddrWORD, value); }
        }

        private int _dataLenWORD = 2;

        public int DataLenWORD
        {
            get { return _dataLenWORD; }
            set { Set(ref _dataLenWORD, value); }
        }

        private string _writeData;

        public string WriteData
        {
            get { return _writeData; }
            set
            {
                value = value.FormatHexString();
                if (value.String2HexArray().Length > DataLenWORD << 1) return;
                Set(ref _writeData, value);
            }
        }

    }
}
