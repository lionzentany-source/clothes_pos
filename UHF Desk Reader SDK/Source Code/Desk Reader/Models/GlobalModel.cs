using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Interop;

namespace UHF_Desk
{
    public class GlobalModel
    {
        /// <summary>
        /// 空密码
        /// </summary>
        public static readonly byte[] EmptyPwd = new byte[] { 0, 0, 0, 0 };
        /// <summary>
        /// 空数组
        /// </summary>
        public static readonly byte[] EmptyArray = new byte[0];

        public static bool IsChinese
        {
            get { return ConfigurationExtend.GetAppConfig("language") == "zh-cn"; }
        }

        public static string Version
        {
            get { return ConfigurationExtend.GetAppConfig("version"); }
        }

        /// <summary>
        /// 触发类型
        /// </summary>
        public static string TriggerType
        {
            get { return ConfigurationExtend.GetAppConfig("trigger_type"); }
        }

        /// <summary>
        /// 触发内容
        /// </summary>
        public static string TriggerContent
        {
            get { return ConfigurationExtend.GetAppConfig("trigger_content"); }
        }
    }
}
