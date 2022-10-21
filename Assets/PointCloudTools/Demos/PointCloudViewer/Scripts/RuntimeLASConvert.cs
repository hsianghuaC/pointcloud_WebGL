// example script to convert LAS/LAZ file at runtime and then read it in regular viewer (as .ucpc format)

using System.Diagnostics;
using System.IO;
using unitycodercom_PointCloudBinaryViewer;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace unitycoder_examples
{
    public class RuntimeLASConvert : MonoBehaviour
    {
        public PointCloudViewerDX11 binaryViewerDX11;
        public string lasFile = "runtime-example.las";

        // inside streaming assets
        [Tooltip("Place your downloaded converter in this folder, or set correct path here (relative to StreamingAssets or absolute path to outside project")]
        public string commandlinePath = "PointCloudConverterX64/PointCloudConverter.exe";


        [HideInInspector]
        public bool isConverting = false;
        string outputPath;

        void Start()
        {
            isConverting = true;

            var sourceFile = lasFile;

            // check if full path or relative to streaming assets
            if (Path.IsPathRooted(sourceFile) == false)
            {
                sourceFile = Path.Combine(Application.streamingAssetsPath, sourceFile);
            }

            if (File.Exists(sourceFile))
            {
                Debug.Log("Converting file: " + sourceFile);
            }
            else
            {
                Debug.LogError("Input file missing: " + sourceFile);
                return;
            }

            outputPath = Path.GetDirectoryName(sourceFile);
            outputPath = Path.Combine(outputPath, "runtime-example.ucpc");

            var exePath = Path.Combine(Application.streamingAssetsPath, commandlinePath);

            // check if converter is available
            if (File.Exists(exePath) == false)
            {
                Debug.LogError("Missing standalone converter exe: " + exePath);
                Debug.Log("You can download it from https://github.com/unitycoder/PointCloudConverter/releases");
                return;
            }

            // NOTE should do this in separate thread, so no need to wait for conversion in mainthread..

            var process = new Process();
            process.StartInfo.FileName = exePath;
            // more params https://github.com/unitycoder/UnityPointCloudViewer/wiki/Commandline-Tools
            process.StartInfo.Arguments = "-input=" + sourceFile + " -swap=true -output=" + outputPath;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
            //startInfo.WindowStyle = ProcessWindowStyle.Minimized;
            //var process = Process.Start(startInfo);
            process.EnableRaisingEvents = true;
            process.OutputDataReceived += ConversionLog;
            process.ErrorDataReceived += ConversionLog;
            process.Exited += ConversionDone;
            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
            //process.WaitForExit();

            //Debug.Log(startInfo.Arguments);
            Debug.Log("[RuntimeLASConvert] Conversion is running..");
        }

        private void ConversionLog(object sender, DataReceivedEventArgs e)
        {
            Debug.Log("<color=grey>[ConverterOutput] " + e.Data+"</color>");
        }

        void ConversionDone(object sender, System.EventArgs e)
        {
            isConverting = false;

            // check if output exists
            if (File.Exists(outputPath))
            {
                Debug.Log("Reading output file: " + outputPath);
                binaryViewerDX11.CallReadPointCloudThreaded(outputPath);
            }
            else
            {
                Debug.LogError("File not found: " + outputPath);
            }

        }
    }
}