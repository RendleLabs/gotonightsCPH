using System;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace bobbins
{
    public static class Influx
    {
        private static readonly string Url = "http://influxdb:8086/query?q=" + Uri.EscapeDataString("CREATE DATABASE data");
        public static async Task Setup()
        {
            using (var client = new HttpClient())
            {
                for (int i = 0; i < 5; i++)
                {
                    try
                    {
                        var cts = new CancellationTokenSource(1000);
                        var res = await client.PostAsync(Url, new StringContent(""), cts.Token);
                        if (res.IsSuccessStatusCode)
                        {
                            return;
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(ex.Message);
                    }
                }
            }
            Console.WriteLine("Failed to create InfluxDB database");
        }
    }
}