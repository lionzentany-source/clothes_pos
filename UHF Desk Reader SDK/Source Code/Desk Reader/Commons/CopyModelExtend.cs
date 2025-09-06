using System;
using System.Reflection;
using System.Text.Json.Serialization;

namespace UHF_Desk
{
    public static class CopyModelExtend
    {
        public static void Copy<T1, T2>(this T1 target, T2 source) where T1 : class where T2 : class
        {
            if (target == null || source == null) return;
            Type type1 = target.GetType();
            Type type2 = source.GetType();
            foreach (var mi in type2.GetProperties())
            {
                if (mi.IsDefined(typeof(JsonIgnoreAttribute)))
                {
                    continue;
                }
                var des = type1.GetProperty(mi.Name);
                if (des != null)
                {
                    try
                    {
                        des.SetValue(target, Convert.ChangeType(mi.GetValue(source, null), des.PropertyType), null);
                    }
                    catch
                    { }
                }
            }
        }
    }
}
