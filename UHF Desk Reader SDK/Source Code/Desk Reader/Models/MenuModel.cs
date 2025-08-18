namespace UHF_Desk
{
    public class MenuModel : BaseModel
    {
        private bool _isSelected;
        [Ignore(true)]
        public bool IsSelected
        {
            get { return _isSelected; }
            set { Set(ref _isSelected, value); }
        }

        public int Key { get; set; }

        public string MenuHeader { get; set; }

        public string TargetView { get; set; }

        public string MenuIcon { get; set; }
    }
}
