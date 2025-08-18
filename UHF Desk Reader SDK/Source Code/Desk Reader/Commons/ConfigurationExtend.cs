using System.Configuration;

namespace UHF_Desk
{
    public static class ConfigurationExtend
    {
        public static string GetConnectionStringsConfig(string connectionName)
        {
            return ConfigurationManager.ConnectionStrings[connectionName].ConnectionString.Obj2String();
        }

        public static void UpdateConnectionStringConfig(string newName, string newConnString, string newProviderName)
        {
            bool isModified = false;
            if (ConfigurationManager.ConnectionStrings[newName] != null)
            {
                isModified = true;
            }

            ConnectionStringSettings settings = new ConnectionStringSettings(newName, newConnString, newProviderName);
            Configuration config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);

            if (isModified)
                config.ConnectionStrings.ConnectionStrings.Remove(newName);

            config.ConnectionStrings.ConnectionStrings.Add(settings);
            config.Save(ConfigurationSaveMode.Modified);
            ConfigurationManager.RefreshSection("ConnectionStrings");
        }

        public static string GetAppConfig(string appName)
        {
            foreach (string key in ConfigurationManager.AppSettings)
            {
                if (key == appName) return ConfigurationManager.AppSettings[appName];
            }
            return null;
        }

        public static void UpdateAppConfig(string newKey, string newValue)
        {
            bool isModified = false;
            foreach (string key in ConfigurationManager.AppSettings)
            {
                if (key == newKey)
                {
                    isModified = true;
                    break;
                }
            }

            Configuration config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);

            if (isModified)
                config.AppSettings.Settings.Remove(newKey);
            config.AppSettings.Settings.Add(newKey, newValue);
            config.Save(ConfigurationSaveMode.Modified);
            ConfigurationManager.RefreshSection("appSettings");
        }
    }
}
