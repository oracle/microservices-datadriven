using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.OracleClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Transactions;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using Newtonsoft.Json;
using Oracle.ManagedDataAccess.Client;

namespace inventory_dotnet
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();
            services
                .AddSwaggerGen(c =>
                {
                    c
                        .SwaggerDoc("v1",
                        new OpenApiInfo {
                            Title = "inventory_dotnet",
                            Version = "v1"
                        });
                });
            ListenForMessages();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app
                    .UseSwaggerUI(c =>
                        c
                            .SwaggerEndpoint("/swagger/v1/swagger.json",
                            "inventory_dotnet v1"));
            }

            app.UseHttpsRedirection();

            app.UseRouting();

            app.UseAuthorization();

            app
                .UseEndpoints(endpoints =>
                {
                    endpoints.MapControllers();
                });
        }

        public String ListenForMessages()
        {
            //Other options include...
            //   using (TransactionScope scope = new TransactionScope(TransactionScopeOption.Required, TimeSpan.MaxValue))
            //   DbProviderFactory factory = DbProviderFactories.GetFactory("Oracle.ManagedDataAccess.Client"); DbCommand oracleCommand = factory.CreateCommand();
            String tnsAdmin = Environment.GetEnvironmentVariable("TNS_ADMIN");
            OracleConfiguration.WalletLocation = tnsAdmin;
            String pw = Environment.GetEnvironmentVariable("DB_PASSWORD");
            string connString =
                "User Id=" +
                Environment.GetEnvironmentVariable("DB_USER") +
                ";Password=" +
                "\"" + pw + "\"" +
                ";Data Source=" +
                Environment.GetEnvironmentVariable("DB_CONNECT_STRING") +
                ";";
        using (
                OracleConnection connection = new OracleConnection(connString)
            )
            {
                connection.Open();
                while (true) {
                    try
                    {
                        Console.WriteLine("listening for messages...");
                        OracleTransaction tx = connection.BeginTransaction();
                        //dequeue from order queues (out param)
                        OracleCommand orderReceiveMessageCommand = new OracleCommand();
                        orderReceiveMessageCommand.Connection = connection;
                        orderReceiveMessageCommand.CommandText = "dequeueOrderMessage";
                        orderReceiveMessageCommand.CommandType = CommandType.StoredProcedure;
                        OracleParameter p_orderInfoParam =
                            new OracleParameter("p_orderInfo",
                                OracleDbType.Varchar2,
                                32767);
                        p_orderInfoParam.Direction = ParameterDirection.Output;
                        orderReceiveMessageCommand.Parameters.Add (p_orderInfoParam);
                        orderReceiveMessageCommand.ExecuteNonQuery();
                        // Console.WriteLine("orderReceiveMessageCommand.Parameters[p_orderInfo].Value:" + orderReceiveMessageCommand.Parameters["p_orderInfo"].Value);
                        if (orderReceiveMessageCommand.Parameters["p_orderInfo"] is null || orderReceiveMessageCommand.Parameters["p_orderInfo"].Value is null) {
                            Console.WriteLine("message was null");
                            System.Threading.Thread.Sleep(1000);
                            continue;
                        }
                        Order order;
                        try {
                            order = JsonConvert.DeserializeObject<Order>(
                                "" + orderReceiveMessageCommand.Parameters["p_orderInfo"].Value);
                        } catch (System.NullReferenceException ex)  {
                            Console.WriteLine("message was null" + ex);
                            System.Threading.Thread.Sleep(1000);
                            continue;
                        } 
                        System
                            .Console
                            .WriteLine("order.itemid inventorychecked sendmessage for {0}",
                            order.orderid);
                        // check inventory (in and out params)
                        OracleCommand checkInventoryReturnLocationCommand =
                            new OracleCommand();
                        checkInventoryReturnLocationCommand.Connection = connection;
                        checkInventoryReturnLocationCommand.CommandText =
                            "checkInventoryReturnLocation";
                        checkInventoryReturnLocationCommand.CommandType =
                            CommandType.StoredProcedure;
                        OracleParameter p_itemIdParam =
                            new OracleParameter("p_inventoryId",
                                OracleDbType.Varchar2,
                                32767);
                        p_itemIdParam.Direction =
                            ParameterDirection.Input;
                        p_itemIdParam.Value = order.itemid;
                        checkInventoryReturnLocationCommand.Parameters.Add (
                            p_itemIdParam
                        );
                        OracleParameter p_inventorylocationParam =
                            new OracleParameter("p_inventorylocation",
                                OracleDbType.Varchar2,
                                32767);
                        p_inventorylocationParam.Direction = ParameterDirection.Output;
                        checkInventoryReturnLocationCommand.Parameters.Add (p_inventorylocationParam);
                        checkInventoryReturnLocationCommand.ExecuteNonQuery();

                        // direct query version (ie not using sproc)...
                        // checkInventoryCommand.CommandText =
                        //     @"update inventory set inventorycount = inventorycount - 1 where inventoryid = " +
                        //     order.itemid +
                        //     " and inventorycount > 0 returning inventorylocation into ?";
                        // OracleParameter p_inventoryCheckParam =
                        //     new OracleParameter("p_orderInfo",
                        //         OracleDbType.Varchar2,
                        //         32767);
                        // p_inventoryCheckParam.Direction =
                        //     ParameterDirection.Output;
                        // oracleCommand.Parameters.Add (p_orderInfoParam);
                        // int retVal = checkInventoryCommand.ExecuteNonQuery();
                        // Console
                        //     .WriteLine("Rows to be affected by checkInventoryCommand: {0}",
                        //     retVal);

                        //inventory status object creation (using inventory location deteremined from query above)
                        Inventory inventory = new Inventory();
                        var inventoryLocation = "" + checkInventoryReturnLocationCommand.Parameters["p_inventorylocation"].Value;
                        inventory.inventorylocation = inventoryLocation.Equals("null") ? "inventorydoesnotexist" : inventoryLocation;
                        inventory.itemid = order.itemid;
                        inventory.orderid = order.orderid;
                        inventory.suggestiveSale = inventoryLocation.Equals("null") ? "" : "beer";
                        string inventoryJSON =
                            JsonConvert.SerializeObject(inventory);
                        System
                            .Console
                            .WriteLine("order.itemid inventoryJSON {0}",
                            inventoryJSON);
                        //enqueue to inventory queue (in param)
                        OracleCommand inventorySendMessageCommand =
                            new OracleCommand();
                        inventorySendMessageCommand.Connection = connection;
                        inventorySendMessageCommand.CommandText =
                            "enqueueInventoryMessage";
                        inventorySendMessageCommand.CommandType =
                            CommandType.StoredProcedure;
                        OracleParameter p_inventoryInfoParam =
                            new OracleParameter("p_inventoryInfo",
                                OracleDbType.Varchar2,
                                32767);
                        p_inventoryInfoParam.Direction =
                            ParameterDirection.Input;
                        p_inventoryInfoParam.Value = inventoryJSON;
                        inventorySendMessageCommand.Parameters.Add (
                            p_inventoryInfoParam
                        );
                        inventorySendMessageCommand.ExecuteNonQuery();
                        tx.Commit();
                    }
                    catch (NullReferenceException ex) {
                        if(ex != null) System.Threading.Thread.Sleep(1000);
                    } 
                }
            }
        }
    }
}
