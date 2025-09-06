using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Effects;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace UHF_Desk
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            ActionManager.Register<object>("MessageDialog", new Func<object, bool>(ShowMessageDialog));
            ActionManager.Register<object>("UpdateEpcDialog", new Func<object, bool>(ShowUpdateEpcDialog));
            ActionManager.Register<object>("ContinuousWriteDialog", new Func<object, bool>(ShowContinuousWriteDialog));
        }

        private bool ShowDialog(Window dialog)
        {
            this.Effect = new BlurEffect() { Radius = 5 };
            bool state = dialog.ShowDialog() == true;
            this.Effect = null;
            return state;
        }

        private void Show(Window dialog)
        {
            dialog.Show();
        }

        private bool ShowMessageDialog(object obj)
        {
            return ShowDialog(new MessageDialog() { Owner = this, DataContext = obj });
        }

        public bool ShowUpdateEpcDialog(object obj)
        {
            return ShowDialog(new UpdateEpcDialog() { Owner = this, DataContext = obj });
        }

        public bool ShowContinuousWriteDialog(object obj)
        {
            return ShowDialog(new ContinuousWriteDialog() { Owner = this, DataContext = obj });
        }
    }
}
