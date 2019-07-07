using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace AEX_Build
{
    class Program
    {
        static string _outputDir = "";

        static void Main(string[] args)
        {
            if (!File.Exists(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "/aexbuild.cfg"))
            {
                Console.Error.WriteLine("aexbuild: ./aexbuild.cfg not found, exiting...");
                return;
            }
            else
            {
                // Yes yes, I know. Primitive but I don't care
                var l = File.ReadAllLines(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "/aexbuild.cfg");
                if (l.Length < 1)
                {
                    Console.Error.WriteLine("aexbuild: ./aexbuild.cfg doesn't contain output dir");
                    return;
                }
                _outputDir = l[0];
            }

            StringBuilder all = new StringBuilder();
            all.Append("--@server\nFiles = {};\n");

            Dictionary<string, long> Usages = new Dictionary<string, long>();
            Dictionary<string, long> Sizes = new Dictionary<string, long>();
            
            foreach (var f in Directory.GetFiles("./", "*.lua", SearchOption.AllDirectories))
            {
                string Ext = ".lua";
                var p_s = f.Substring(1).Replace('\\', '/').Split('.');
                string Path = string.Join(".", p_s, 0, p_s.Length - 1);

                string[] Lines = File.ReadAllLines(f);

                for (int ln = 0; ln < Math.Min(10, Lines.Length - 1); ln++)
                {
                    var exp = Lines[ln].Split(' ');
                    if (exp[0] == "--@EXT")
                        Ext = "." + exp[1];
                }

                if (!Usages.ContainsKey(Ext))
                    Usages[Ext] = 0;

                Usages[Ext] += Lines.Length;
                Console.WriteLine(Path + Ext);

                Sizes[Path + Ext] = Lines.Length;
                
                string file = string.Join("\n", Lines);
                if (Ext == ".lxe" || Ext == ".lax") // Lua Executables and Lua Application Extensions
                    file = "LXE\n:version 1\n:format AEXSTDLXE\n:os AEX/2\n:cpu rH72\n;compressed\n]] .. fastlz.compress([[" + file +  "]]) .. [[\n";

                all.Append(string.Format("Files['{0}'] = [[\n", Path + Ext));
                all.Append(file);
                all.Append("\n]]\n");
            }
            all.Append("return Files;");

            Console.WriteLine("");
            Console.WriteLine("Longest files: ");

            int i = 0;
            foreach (var item in Sizes.OrderByDescending(key => key.Value))
            {
                if (++i > 5)
                    break;

                Console.WriteLine(item.Key + " - " + item.Value);
            }
            Console.WriteLine("");

            string Total = all.ToString();
            long TotalLines = Total.Count(f => f == '\n');

            foreach (var item in Usages)
                Console.WriteLine(" " + item.Key.PadRight(6) + (Math.Round((((double)(item.Value))/Total.Count(f => f == '\n')) * 100, 2) + " % ").PadRight(9) + item.Value);

            Console.WriteLine("Total lines : " + TotalLines);
            Console.WriteLine("Total size  : " + Total.Length);

            Directory.CreateDirectory(_outputDir + "/");
            File.WriteAllText(_outputDir + "/all.txt", Total);
        }
    }
}
