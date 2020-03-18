using System.Data.SqlClient;
using System.Text;
using System.Threading.Tasks;
using Medumo.WebJobs.Extensions.EventHub.Binding;
using Microsoft.Azure.EventHubs;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using StackExchange.Redis;
using System.Linq;
using System;
using System.Data;

namespace EventHubConsumer
{
    public class Settings
    {
        public int Delay { get; set; }
        public bool SkipAll { get; set; }
        public string DbConnection { get; set; }
        public int TestRun { get; set; }
    }

    internal static class SettingsExtensions
    {
        public static Settings ToSettings(this IConfiguration config)
        {
            var settings = new Settings
            {
                DbConnection = config["Settings__DbConnection"],
                Delay = int.Parse(config["Settings__Delay"] ?? "0"),
                SkipAll = bool.Parse(config["Settings__SkipAll"] ?? "false"),
                TestRun = int.Parse(config["Settings__TestRun"] ?? "777"),
            };
            return settings;
        }
    }

    public class Trigger
    {
        private ILogger<Trigger> Log { get; }
        private Settings Settings { get; }
        //private static ConnectionMultiplexer redis = ConnectionMultiplexer.Connect("localhost");
        //private static IDatabase db = redis.GetDatabase();

        public Trigger(ILogger<Trigger> logger, IOptions<Settings> config)
        {
            Log = logger;
            Settings = config.Value;
            Log.LogTrace("delay: {delay}, skipall: {skipall}, db: {db}, testrun: {testrun}",
                Settings.Delay,
                Settings.SkipAll,
                Settings.DbConnection,
                Settings.TestRun);
        }

        //public async Task Run([SafeEventHubTrigger("testhub32", Connection = "EventHubConnectionString")]
        //    EventData[] eventDataSet)
        //{
        //    Log.LogInformation("Triggered batch of size {eventDataSet}", eventDataSet.Length);
        //    foreach (var eventData in eventDataSet)
        //    {
        //        try
        //        {
        //            await db.ListRightPushAsync("events:" + eventData.Properties["partitionKey"],
        //                (string) eventData.Properties["counter"]);
        //        }
        //        catch
        //        {
        //            // handle event exception
        //        }
        //    }
        //}

        //public async Task Run([SafeEventHubTrigger("testhub32", Connection = "EventHubConnectionString")]
        //    EventData message)
        //{
        //    if (Settings.SkipAll) return;
        //    var body = Encoding.UTF8.GetString(message.Body);
        //    //Log.LogInformation(
        //    //    "Partition key: {partitionKey}, offset: {offset}, sequence number: {sequenceNumber},  body: {body}",
        //    //    message.SystemProperties.PartitionKey, message.SystemProperties.Offset,
        //    //    message.SystemProperties.SequenceNumber, body);
        //    //Log.LogInformation("{partitionKey}", message.SystemProperties.PartitionKey);
        //    Log.LogInformation(
        //    "Partition key: {partitionKey}, enqueued time: {enqueuedTime}, offset: {offset}, sequence number: {sequenceNumber}, body: {body}",
        //    message.SystemProperties.PartitionKey, message.SystemProperties.EnqueuedTimeUtc,
        //    message.SystemProperties.Offset,
        //    message.SystemProperties.SequenceNumber, body);
        //    await Task.Delay(Settings.Delay);
        //    await db.ListRightPushAsync(
        //        //$"events:{message.SystemProperties.PartitionKey},timestamp:{DateTime.UtcNow.ToString("mm:ss.ffffff tt")},enqueue:{message.SystemProperties.EnqueuedTimeUtc.ToString("mm:ss.ffffff tt")},origCounter:{message.Properties["counter"]}",
        //        // counter, partition key, processing time, enqueued time
        //        $"{message.SystemProperties.PartitionKey},{DateTime.UtcNow.ToString("mm:ss.ffffff")},{message.SystemProperties.EnqueuedTimeUtc.ToString("mm:ss.ffffff")},{message.Properties["counter"]}",
        //        message.Properties["counter"].ToString());
        //}

        public async Task Run([SafeEventHubTrigger("%EventHubName%", Connection = "EventHubConnectionString")]
            EventData message)
        {
            if (Settings.SkipAll) return;
            var body = Encoding.UTF8.GetString(message.Body);
            Log.LogInformation(
            "Partition key: {partitionKey}, enqueued time: {enqueuedTime}, offset: {offset}, sequence number: {sequenceNumber}, body: {body}",
            message.SystemProperties.PartitionKey, message.SystemProperties.EnqueuedTimeUtc,
            message.SystemProperties.Offset,
            message.SystemProperties.SequenceNumber, body);
            await Task.Delay(Settings.Delay);
            //await db.ListRightPushAsync(
            //    //$"events:{message.SystemProperties.PartitionKey},timestamp:{DateTime.UtcNow.ToString("mm:ss.ffffff tt")},enqueue:{message.SystemProperties.EnqueuedTimeUtc.ToString("mm:ss.ffffff tt")},origCounter:{message.Properties["counter"]}",
            //    // counter, partition key, processing time, enqueued time
            //    $"{message.SystemProperties.PartitionKey},{DateTime.UtcNow.ToString("mm:ss.ffffff")},{message.SystemProperties.EnqueuedTimeUtc.ToString("mm:ss.ffffff")},{message.Properties["counter"]}",
            //    message.Properties["counter"].ToString());
            var model = new Model
            {
                PartitionKey = message.SystemProperties.PartitionKey,
                CreatedAt = DateTime.UtcNow,
                EnqueuedTimeUtc = message.SystemProperties.EnqueuedTimeUtc,
                EnqueuedCounter = message.Properties["counter"].ToString(),
                Body = body,
                TestRun = Settings.TestRun,
            };
            string SQL_INSERT = $@"INSERT INTO [dbo].[EhTests]
               ([TestRun]
               ,[PartitionKey]
               ,[PartitionKeyPrefix]
               ,[PartitionKeySuffix]
               ,[CreatedAt]
               ,[EnqueuedTimeUtc]
               ,[EnqueuedCounter]
               ,[Body])
             VALUES
               (@{nameof(model.TestRun)}
               ,@{nameof(model.PartitionKey)}
               ,@{nameof(model.PartitionKeyPrefix)}
               ,@{nameof(model.PartitionKeySuffix)}
               ,@{nameof(model.CreatedAt)}
               ,@{nameof(model.EnqueuedTimeUtc)}
               ,@{nameof(model.EnqueuedCounter)}
               ,@{nameof(model.Body)})";
            using (var connection = new SqlConnection(Settings.DbConnection))
            {
                using (SqlCommand command = new SqlCommand())
                {
                    command.Connection = connection;
                    command.CommandType = CommandType.Text;
                    command.CommandText = SQL_INSERT;
                    command.Parameters.AddWithValue($"@{nameof(model.TestRun)}", model.TestRun);
                    command.Parameters.AddWithValue($"@{nameof(model.PartitionKey)}", model.PartitionKey);
                    command.Parameters.AddWithValue($"@{nameof(model.PartitionKeyPrefix)}", model.PartitionKeyPrefix);
                    command.Parameters.AddWithValue($"@{nameof(model.PartitionKeySuffix)}", model.PartitionKeySuffix);
                    command.Parameters.AddWithValue($"@{nameof(model.CreatedAt)}", model.CreatedAt);
                    command.Parameters.AddWithValue($"@{nameof(model.EnqueuedTimeUtc)}", model.EnqueuedTimeUtc);
                    command.Parameters.AddWithValue($"@{nameof(model.EnqueuedCounter)}", model.EnqueuedCounter);
                    command.Parameters.AddWithValue($"@{nameof(model.Body)}", model.Body);

                    try
                    {
                        connection.Open();
                        int recordsAffected = command.ExecuteNonQuery();
                    }
                    finally
                    {
                        connection.Close();
                    }
                }

            }
        }
    }

    internal class Model
    {
        public string PartitionKey { get; internal set; }
        public string PartitionKeyPrefix => PartitionKey.Split("_").First();
        public string PartitionKeySuffix => PartitionKey.Split("_").Last();
        public object CreatedAt { get; internal set; }
        public DateTime EnqueuedTimeUtc { get; internal set; }
        public string EnqueuedCounter { get; internal set; }
        public string Body { get; internal set; }
        public int TestRun { get; internal set; }
    }
}
