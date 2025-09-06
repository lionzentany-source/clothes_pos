using System;

namespace UHF_Desk
{
    public class IgnoreAttribute : Attribute
    {
        public bool Ignore { get; set; }

        public IgnoreAttribute(bool ignore)
        {
            Ignore = ignore;
        }
    }
}
