namespace UHF_Desk
{
    public class LockTagModel : BaseModel
    {
        private bool _isAccessingPwdArea;

        public bool IsAccessingPwdArea
        {
            get { return _isAccessingPwdArea; }
            set { Set(ref _isAccessingPwdArea, value); }
        }

        private bool _isKillPwdArea;

        public bool IsKillPwdArea
        {
            get { return _isKillPwdArea; }
            set { Set(ref _isKillPwdArea, value); }
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

        private bool _isOpenness = true;

        public bool IsOpenness
        {
            get { return _isOpenness; }
            set { Set(ref _isOpenness, value); }
        }

        private bool _isLock;

        public bool IsLock
        {
            get { return _isLock; }
            set { Set(ref _isLock, value); }
        }

        private bool _isPermanentOpenness;

        public bool IsPermanentOpenness
        {
            get { return _isPermanentOpenness; }
            set { Set(ref _isPermanentOpenness, value); }
        }

        private bool _isPermanentLock;

        public bool IsPermanentLock
        {
            get { return _isPermanentLock; }
            set { Set(ref _isPermanentLock, value); }
        }

        private string _accessPwdHEX = "00 00 00 00";

        public string AccessPwdHEX
        {
            get { return _accessPwdHEX; }
            set
            {
                value = value.FormatHexString();
                if (value.String2HexArray().Length > 4) return;
                Set(ref _accessPwdHEX, value);
            }
        }

        private string _killPwdHEX = "00 00 00 00";

        public string KillPwdHEX
        {
            get { return _killPwdHEX; }
            set
            {
                value = value.FormatHexString();
                if (value.String2HexArray().Length > 4) return;
                Set(ref _killPwdHEX, value);
            }
        }

    }
}
