using System.Threading.Tasks;
using Medumo.WebJobs.Extensions.EventHub.Extensions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EventHubConsumer
{
    internal class Program
    {
        private static async Task Main(string[] args)
        {
            var hostBuilder = new HostBuilder()
                .ConfigureAppConfiguration((configBuilder) =>
                {
                    configBuilder
                    .AddEnvironmentVariables()
                    .AddJsonFile("local.settings.json", optional: true);
                })
                .ConfigureWebJobs(builder =>
                {
                    builder
                        .AddAzureStorageCoreServices()
                        .AddSafeEventHubs();

                    builder.Services.AddOptions<Settings>()
                        .Configure<IConfiguration>((settings, config) =>
                            {
                                config.GetSection("Settings").Bind(settings);
                            });
                })
                .ConfigureLogging((context, logger) =>
                {
                    logger.AddConsole();

                    // If this key exists in any config, use it to enable App Insights
                    string appInsightsKey = context.Configuration["APPINSIGHTS_INSTRUMENTATIONKEY"];
                    if (!string.IsNullOrEmpty(appInsightsKey))
                    {
                        logger.AddApplicationInsightsWebJobs(o => o.InstrumentationKey = appInsightsKey);
                    }

                    logger.AddConfiguration(context.Configuration.GetSection("Logging"));
                })
                .UseConsoleLifetime();

            var host = hostBuilder.Build();
            using (host)
            {
                await host.RunAsync();
            }
        }
    }
}
