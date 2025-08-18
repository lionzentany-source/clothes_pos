using GalaSoft.MvvmLight;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.CompilerServices;

namespace UHF_Desk
{
    public class BaseModel : ObservableObject
    {
        private bool _isChanged = false;

        public bool IsChanged
        {
            get { return _isChanged; }
            set { _isChanged = value; }
        }

        protected bool Set<T>(ref T field, T newValue, [CallerMemberName] string propertyName = null)
        {
            PropertyInfo pi = GetType().GetProperty(propertyName);
            if (!pi.IsDefined(typeof(IgnoreAttribute), true))
            {
                if (field != null && !EqualityComparer<T>.Default.Equals(field, newValue))
                {
                    IsChanged = true;
                }
            }

            return Set(propertyName, ref field, newValue);
        }
    }
}
