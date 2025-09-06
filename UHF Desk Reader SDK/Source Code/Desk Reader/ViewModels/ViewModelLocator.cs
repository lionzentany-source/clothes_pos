using CommonServiceLocator;
using GalaSoft.MvvmLight.Ioc;

namespace UHF_Desk
{
    public class ViewModelLocator
    {
        public MainWindowViewModel MainWindowViewModel => ServiceLocator.Current.GetInstance<MainWindowViewModel>();
        public InquiryViewModel InquiryViewModel => ServiceLocator.Current.GetInstance<InquiryViewModel>();
        public ReadWriteViewModel ReadWriteViewModel => ServiceLocator.Current.GetInstance<ReadWriteViewModel>();
        public SetUpViewModel SetUpViewModel => ServiceLocator.Current.GetInstance<SetUpViewModel>();

        public ViewModelLocator()
        {
            ServiceLocator.SetLocatorProvider(() => SimpleIoc.Default);

            SimpleIoc.Default.Register<MainWindowViewModel>();
            SimpleIoc.Default.Register<InquiryViewModel>();
            SimpleIoc.Default.Register<ReadWriteViewModel>();
            SimpleIoc.Default.Register<SetUpViewModel>();
        }
    }
}
