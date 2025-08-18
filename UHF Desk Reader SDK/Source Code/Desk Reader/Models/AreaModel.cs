namespace UHF_Desk
{
    public class AreaModel : BaseModel
    {
        private string _area;
        [Ignore(true)]
        public string Area
        {
            get { return _area; }
            set { Set(ref _area, value); }
        }

        private int _areaIndex;
        [Ignore(true)]
        public int AreaIndex
        {
            get { return _areaIndex; }
            set { Set(ref _areaIndex, value); }
        }

        private bool _isChecked;
        [Ignore(true)]
        public bool IsChecked
        {
            get { return _isChecked; }
            set { Set(ref _isChecked, value); }
        }
    }
}
