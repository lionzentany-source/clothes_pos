using System.Windows;

namespace UHF_Desk
{
    public class MessageModel : BaseModel
    {
        private string _title;

        public string Title
        {
            get { return _title; }
            set { Set(ref _title, value); }
        }

        private string _message;

        public string Message
        {
            get { return _message; }
            set { Set(ref _message, value); }
        }

        private Visibility _visual = Visibility.Collapsed;

        public Visibility Visual
        {
            get { return _visual; }
            set { Set(ref _visual, value); }
        }
    }
}
