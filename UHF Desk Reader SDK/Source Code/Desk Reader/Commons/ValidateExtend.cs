using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace UHF_Desk
{
    /// <summary>
    /// 验证扩展
    /// </summary>
    public static class ValidateExtend
    {
        /// <summary>
        /// （Int）是否在区间内
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="begin">开始区间</param>
        /// <param name="end">结束区间</param>
        /// <returns>True:是 False:否</returns>
        public static bool IsInRange(this int thisValue, int begin, int end)
        {
            return thisValue >= begin && thisValue <= end;
        }

        /// <summary>
        /// （DateTime）是否在区间内
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="begin">开始区间</param>
        /// <param name="end">结束区间</param>
        /// <returns>True:是 False:否</returns>
        public static bool IsInRange(this DateTime thisValue, DateTime begin, DateTime end)
        {
            return thisValue >= begin && thisValue <= end;
        }

        /// <summary>
        /// values是否包含thisValue
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="thisValue">thisValue</param>
        /// <param name="values">values</param>
        /// <returns>True:是 False:否</returns>
        public static bool IsIn<T>(this T thisValue, params T[] values)
        {
            return values.Contains(thisValue);
        }

        /// <summary>
        /// thisValue是否包含inValues
        /// </summary>
        /// <param name="thisValue">thisValue</param>
        /// <param name="inValues">inValues</param>
        /// <returns>True:是 False:否</returns>
        public static bool IsContainsIn(this string thisValue, params string[] inValues)
        {
            return inValues.Any(it => thisValue.Contains(it));
        }

        /// <summary>
        /// （Obejct）是否为NULL或则为空
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsNullOrEmpty(this object thisValue)
        {
            if (thisValue == null || thisValue == DBNull.Value) return true;
            return thisValue.ToString() == "";
        }

        /// <summary>
        /// （Guid?）是否为NULL或则为空
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsNullOrEmpty(this Guid? thisValue)
        {
            if (thisValue == null) return true;
            return thisValue == Guid.Empty;
        }

        /// <summary>
        /// （Guid）是否为NULL或则为空
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsNullOrEmpty(this Guid thisValue)
        {
            if (thisValue == null) return true;
            return thisValue == Guid.Empty;
        }

        /// <summary>
        /// （IEnumerable<object>）是否为NULL或则为空
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsNullOrEmpty(this IEnumerable<object> thisValue)
        {
            if (thisValue == null || thisValue.Count() == 0) return true;
            return false;
        }

        /// <summary>
        /// （Object）是否拥有值（不为 NULL 和 DBNull.Value）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool HasValue(this object thisValue)
        {
            if (thisValue == null || thisValue == DBNull.Value) return false;
            return thisValue.ToString() != "";
        }

        /// <summary>
        /// （IEnumerable<object>）是否拥有值（不为 NULL 和 DBNull.Value）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool HasValue(this IEnumerable<object> thisValue)
        {
            if (thisValue == null || thisValue.Count() == 0) return false;
            return true;
        }

        /// <summary>
        /// （IEnumerable<KeyValuePair<string, string>>）是否拥有值（不为 NULL 和 DBNull.Value）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsValuable(this IEnumerable<KeyValuePair<string, string>> thisValue)
        {
            if (thisValue == null || thisValue.Count() == 0) return false;
            return true;
        }

        /// <summary>
        /// 是否为NULL或则为0
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsZero(this object thisValue)
        {
            return (thisValue == null || thisValue.ToString() == "0");
        }

        /// <summary>
        /// 是否为整数型（Int）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsInt(this object thisValue)
        {
            if (thisValue == null) return false;
            return Regex.IsMatch(thisValue.ToString(), @"^\d+$");
        }

        /// <summary>
        /// 是否为非整数型（!Int）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsNoInt(this object thisValue)
        {
            if (thisValue == null) return true;
            return !Regex.IsMatch(thisValue.ToString(), @"^\d+$");
        }

        /// <summary>
        /// 是否为浮点型（Double/Money）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsMoney(this object thisValue)
        {
            if (thisValue == null) return false;
            double outValue = 0;
            return double.TryParse(thisValue.ToString(), out outValue);
        }

        /// <summary>
        /// 是否为Guid
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsGuid(this object thisValue)
        {
            if (thisValue == null) return false;
            Guid outValue = Guid.Empty;
            return Guid.TryParse(thisValue.ToString(), out outValue);
        }

        /// <summary>
        /// 是否为日期（Date）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsDate(this object thisValue)
        {
            if (thisValue == null) return false;
            DateTime outValue = DateTime.MinValue;
            return DateTime.TryParse(thisValue.ToString(), out outValue);
        }

        /// <summary>
        /// 是否为Email
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsEamil(this object thisValue)
        {
            if (thisValue == null) return false;
            return Regex.IsMatch(thisValue.ToString(), @"^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$");
        }

        /// <summary>
        /// 是否为手机
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsMobile(this object thisValue)
        {
            if (thisValue == null) return false;
            return Regex.IsMatch(thisValue.ToString(), @"^\d{11}$");
        }

        /// <summary>
        /// 是否为电话
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsTelephone(this object thisValue)
        {
            if (thisValue == null) return false;
            return Regex.IsMatch(thisValue.ToString(), @"^(\(\d{3,4}\)|\d{3,4}-|\s)?\d{8}$");
        }

        /// <summary>
        /// 是否为身份证
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsIDcard(this object thisValue)
        {
            if (thisValue == null) return false;
            return Regex.IsMatch(thisValue.ToString(), @"^(\d{15}$|^\d{18}$|^\d{17}(\d|X|x))$");
        }

        /// <summary>
        /// 是否为传真
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsFax(this object thisValue)
        {
            if (thisValue == null) return false;
            return Regex.IsMatch(thisValue.ToString(), @"^[+]{0,1}(\d){1,3}[ ]?([-]?((\d)|[ ]){1,12})+$");
        }

        /// <summary>
        /// 是否为数值型（Numeric）
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsNumeric(this object thisValue)
        {
            if (thisValue == null) return false;
            try
            {
                string val = thisValue.ToString();
                if (val == string.Empty) return false;
                for (int i = 0; i < val.Length; i++)
                {
                    if (val[i].ToString() == "/" || val[i].ToString() == "*" || val[i].ToString() == "+" || (val[i].ToString() == "-" && val.Length == 1))
                        return false;
                    int intCode = Convert.ToInt32(val[i]);
                    if (i == 0)
                    {
                        if (intCode < 45 || intCode > 57) return false;
                    }
                    else
                        if (intCode < 46 || intCode > 57) return false;
                }
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// 正则表达式验证
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="pattern">正则表达式</param>
        /// <returns>True:是 False:否</returns>
        public static bool IsMatch(this object thisValue, string pattern)
        {
            if (thisValue == null) return false;
            Regex reg = new Regex(pattern);
            return reg.IsMatch(thisValue.ToString());
        }

        /// <summary>
        /// 是否为列表
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsCollectionsList(this string thisValue)
        {
            return (thisValue + "").StartsWith("System.Collections.Generic.List") || (thisValue + "").StartsWith("System.Collections.Generic.IEnumerable");
        }

        /// <summary>
        /// 是否为字符串
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsStringArray(this string thisValue)
        {
            return (thisValue + "").IsMatch(@"System\.[a-z,A-Z,0-9]+?\[\]");
        }

        /// <summary>
        /// 是否为枚举
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns>True:是 False:否</returns>
        public static bool IsEnumerable(this string thisValue)
        {
            return (thisValue + "").StartsWith("System.Linq.Enumerable");
        }

        /// <summary>
        /// 是否为十六进制
        /// </summary>
        /// <param name="ch"></param>
        /// <returns></returns>
        public static bool IsHex(char ch)
        {
            return ch >= '0' && ch <= '9' || ch >= 'A' && ch <= 'F' || ch >= 'a' && ch <= 'f';
        }

        /// <summary>
        /// 是否为空
        /// </summary>
        /// <param name="ch"></param>
        /// <returns></returns>
        public static bool IsSpec(char ch)
        {
            return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';
        }
    }
}
