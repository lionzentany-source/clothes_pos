using System.Windows.Data;

namespace UHF_Desk
{
    public class DynamicColumnModel : BaseModel
    {
        private string _name;
        /// <summary>
        /// 中文名
        /// </summary>
        [Ignore(true)]
        public string Name
        {
            get { return _name; }
            set { Set(ref _name, value); }
        }

        private bool _isShow;
        /// <summary>
        /// 是否显示
        /// </summary>
        [Ignore(true)]
        public bool IsShow
        {
            get { return _isShow; }
            set { Set(ref _isShow, value); }
        }

        private Binding _binding;
        /// <summary>
        /// 绑定的值
        /// </summary>
        [Ignore(true)]
        public Binding Binding
        {
            get { return _binding; }
            set { Set(ref _binding, value); }
        }

        private int _width;
        /// <summary>
        /// 宽
        /// </summary>
        [Ignore(true)]
        public int Width
        {
            get { return _width; }
            set { Set(ref _width, value); }
        }
    }
}
