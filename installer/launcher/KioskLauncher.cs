// KioskLauncher - Shell Launcher uchun kichik qobiq (ADR-037).
//
// Shell Launcher ilovani shell qilib ishlatsa, ilova yangilanish uchun
// yopilganda Windows uni darhol qayta ochadi va installer fayllarni
// almashtira olmaydi. Shuning uchun shell = shu launcher:
//   - ilovani KIOSK_LAUNCHER=1 bilan ochadi va yopilishini kutadi;
//   - updating.flag bo'lsa - installer tugashini kutib, keyin qayta ochadi;
//   - exit.flag bo'lsa ("Chiqish" PIN bilan) - qayta ochmaydi;
//   - tez-tez yiqilsa - sekinlashadi.
// Konsol oynasi yo'q (/target:winexe). Ilova bilan bir papkada turadi va
// installer uni yangilamaydi (onlyifdoesntexist) - o'zi ishlab turgan bo'ladi.
//
// Yig'ish (release-windows.ps1 o'zi qiladi):
//   csc /nologo /target:winexe /out:KioskLauncher.exe KioskLauncher.cs
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;

static class KioskLauncher
{
    static readonly string Dir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
    static readonly string UpdatingFlag = Path.Combine(Dir, "updating.flag");
    static readonly string ExitFlag = Path.Combine(Dir, "exit.flag");
    static readonly string LogFile = Path.Combine(Dir, "launcher.log");
    static readonly int Session = Process.GetCurrentProcess().SessionId;

    [STAThread]
    static int Main(string[] args)
    {
        bool created;
        string mutexName = "Local\\QabulxonaKioskLauncher_" +
            Dir.ToLowerInvariant().Replace('\\', '_').Replace(':', '_');
        using (var mutex = new Mutex(true, mutexName, out created))
        {
            if (!created) return 0; // boshqa nusxa ishlayapti

            string exe = args.Length > 0 ? args[0] : DetectApp();
            if (exe == null)
            {
                Log("ilova .exe topilmadi: " + Dir);
                return 1;
            }
            if (!Path.IsPathRooted(exe)) exe = Path.Combine(Dir, exe);

            // Explorer allaqachon ishlayotgan bo'lsa - biz shell emasmiz
            // (masalan autostart yoki qo'lda ochilgan)
            bool isShell = !ExplorerRunning();
            Log("start: " + exe + (isShell ? " (shell)" : " (shell emas)"));

            int quickFails = 0;
            while (true)
            {
                WaitForUpdate();

                if (File.Exists(ExitFlag))
                {
                    if (!isShell)
                    {
                        TryDelete(ExitFlag);
                        Log("chiqish so'raldi - launcher yopiladi");
                        return 0;
                    }
                    // Shell rejimi: texnik explorer'da ishlayapti - u yopilguncha kutamiz
                    Log("chiqish so'raldi - explorer yopilguncha kutiladi");
                    while (true)
                    {
                        Thread.Sleep(3000);
                        if (!ExplorerRunning()) break;
                    }
                    TryDelete(ExitFlag);
                }

                if (!File.Exists(exe))
                {
                    Log("ilova yo'q: " + exe);
                    Thread.Sleep(5000);
                    continue;
                }

                var sw = Stopwatch.StartNew();
                int code = RunApp(exe);
                sw.Stop();
                Log("ilova yopildi: code=" + code + ", " + (int)sw.Elapsed.TotalSeconds + " s");

                if (File.Exists(UpdatingFlag) || File.Exists(ExitFlag))
                {
                    quickFails = 0;
                    continue;
                }

                quickFails = sw.Elapsed.TotalSeconds < 10 ? quickFails + 1 : 0;
                Thread.Sleep(quickFails >= 3 ? 15000 : 1000);
            }
        }
    }

    static int RunApp(string exe)
    {
        try
        {
            var psi = new ProcessStartInfo(exe)
            {
                UseShellExecute = false,
                WorkingDirectory = Path.GetDirectoryName(exe),
            };
            psi.EnvironmentVariables["KIOSK_LAUNCHER"] = "1";
            using (var p = Process.Start(psi))
            {
                p.WaitForExit();
                return p.ExitCode;
            }
        }
        catch (Exception e)
        {
            Log("ishga tushmadi: " + e.Message);
            return -1;
        }
    }

    /// updating.flag ichida - installer jarayon nomi (.exe siz).
    static void WaitForUpdate()
    {
        if (!File.Exists(UpdatingFlag)) return;
        string name = "";
        try { name = File.ReadAllText(UpdatingFlag).Trim(); } catch { }
        Log("yangilanish kutilmoqda: " + name);

        var deadline = DateTime.Now.AddMinutes(15);
        int goneFor = 0;
        // installer endi ishga tushayotgan bo'lishi mumkin - biroz kutamiz
        Thread.Sleep(2000);
        while (DateTime.Now < deadline)
        {
            bool running = name.Length > 0 && Process.GetProcessesByName(name).Length > 0;
            goneFor = running ? 0 : goneFor + 1;
            if (goneFor >= 3) break;
            Thread.Sleep(1000);
        }
        if (DateTime.Now >= deadline) Log("installer 15 daqiqada tugamadi - ilova ochiladi");
        TryDelete(UpdatingFlag);
        Thread.Sleep(1000);
    }

    static bool ExplorerRunning()
    {
        return Process.GetProcessesByName("explorer").Any(p => p.SessionId == Session);
    }

    static string DetectApp()
    {
        string self = Path.GetFileName(Process.GetCurrentProcess().MainModule.FileName);
        return Directory.GetFiles(Dir, "*.exe")
            .Select(Path.GetFileName)
            .Where(n => !n.Equals(self, StringComparison.OrdinalIgnoreCase)
                     && !n.StartsWith("unins", StringComparison.OrdinalIgnoreCase))
            .OrderBy(n => n)
            .FirstOrDefault();
    }

    static void TryDelete(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); } catch { }
    }

    static void Log(string msg)
    {
        try
        {
            var fi = new FileInfo(LogFile);
            if (fi.Exists && fi.Length > 512 * 1024) fi.Delete();
            File.AppendAllText(LogFile, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "  " + msg + Environment.NewLine);
        }
        catch { }
    }
}
