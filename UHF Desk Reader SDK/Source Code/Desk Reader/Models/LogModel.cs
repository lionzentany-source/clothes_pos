using System;

namespace UHF_Desk
{
    public class LogModel : BaseModel
    {
        private string _tips;

        public string Tip
        {
            get { return _tips; }
            set { Set(ref _tips, value); }
        }

        private DateTime _logTime;

        public DateTime LogTime
        {
            get { return _logTime; }
            set { Set(ref _logTime, value); }
        }
    }
}
