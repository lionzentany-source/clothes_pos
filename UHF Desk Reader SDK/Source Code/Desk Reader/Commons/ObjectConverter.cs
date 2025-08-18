using System;
using System.Globalization;
using System.Linq;
using System.Windows.Data;

namespace UHF_Desk
{
    /// <summary>
    /// 单值通用转换器
    /// </summary>
    public class ObjectConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            string[] parray = parameter.Obj2String().ToLower().Split(':');
            if (value == null)
                return ConvertManage.ConvertValue(parray[2], parray[3]);  //如果数据源为空，默认返回false返回值
            if (parray[0].Contains("|"))  //判断是否多值比较 有一个值满足即可
                return ConvertManage.ConvertValue(parray[0].Split('|').Contains(value.Obj2String().ToLower()) ? parray[1] : parray[2], parray[3]);  //多值比较
            return ConvertManage.ConvertValue(parray[0].Equals(value.Obj2String().ToLower()) ? parray[1] : parray[2], parray[3]);  //单值比较
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            string[] parray = parameter.Obj2String().ToLower().Split(':');
            if (value == null)
                return ConvertManage.ConvertValue(parray[2], parray[3]);
            var valueStr = value.Obj2String().ToLower();
            if (valueStr != parray[1])
                return ConvertManage.ConvertValue(parray[2], parray[3]);
            else
                return parray[0].Contains('|') ? parray[0].Split('|')[0] : parray[0];
        }
    }
}
