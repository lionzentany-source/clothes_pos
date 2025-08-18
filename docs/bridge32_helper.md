# bridge32_helper

عملية وسيطة (x86) للتعامل مع UHFPrimeReader.dll (32-bit) وتمرير العلامات لتطبيق Flutter (x64).

## البروتوكول

الإخراج (stdout) JSON Lines:

- {"event":"ready"}
- {"event":"tag","epc":"HEX..."}
- {"event":"error","message":"..."}

الدخل (stdin) JSON Lines:

- {"cmd":"start"}
- {"cmd":"stop"}
- {"cmd":"shutdown"}

## بناء المشروع

أنشئ مشروع .NET Framework أو .NET 6 Console موجه x86 فقط.

## الخطوات المختصرة (PowerShell):

```
dotnet new console -n Bridge32 -f net6.0
```

ثم عدل csproj:

```
<PropertyGroup>
  <PlatformTarget>x86</PlatformTarget>
  <OutputType>Exe</OutputType>
  <TargetFramework>net6.0</TargetFramework>
  <ImplicitUsings>enable</ImplicitUsings>
  <Nullable>enable</Nullable>
</PropertyGroup>
```

ضع Program.cs و ReaderNative.cs و Models.cs كما في هذا المجلد.

انسخ UHFPrimeReader.dll و hidapi.dll بجوار Bridge32.exe.

شغّل:

```
dotnet build -c Release
```

ثم حدّث المسار في di_modules.dart إلى exe الناتج.
