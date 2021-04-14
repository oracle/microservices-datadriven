using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;


using System.Text;
using System.Data.OracleClient;
using System.Data;
using Newtonsoft.Json;
using Oracle.ManagedDataAccess.Client;

using System.Data.Common;
using System.Transactions;

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
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "inventory_dotnet", Version = "v1" });
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
                app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "inventory_dotnet v1"));
            }

            app.UseHttpsRedirection();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }

        public String ListenForMessages()
        {
            //Other options include...
            //   using (TransactionScope scope = new TransactionScope(TransactionScopeOption.Required, TimeSpan.MaxValue))
            //   DbProviderFactory factory = DbProviderFactories.GetFactory("Oracle.ManagedDataAccess.Client"); DbCommand oracleCommand = factory.CreateCommand();
            OracleConfiguration.WalletLocation = Environment.GetEnvironmentVariable("TNS_ADMIN"); 
            using (OracleConnection connection = 
                new OracleConnection("User Id=INVENTORYUSER;Password=" + Environment.GetEnvironmentVariable("dbpassword") + ";Data Source=inventorydb_tp;"))
            { 
                Console.WriteLine("connection:" + connection);
                OracleCommand oracleCommand = new OracleCommand();
                oracleCommand.Connection = connection;
                oracleCommand.CommandText = "dequeueOrderMessage";
                oracleCommand.CommandType = CommandType.StoredProcedure;
                OracleParameter p_orderInfoParam = new OracleParameter("p_orderInfo", OracleDbType.Varchar2, 32767);
                p_orderInfoParam.Direction = ParameterDirection.Output;
                oracleCommand.Parameters.Add(p_orderInfoParam);


                try
                {
                    connection.Open();
                    while(true) {
                        oracleCommand.ExecuteNonQuery();
                        Order order = JsonConvert.DeserializeObject<Order>("" + oracleCommand.Parameters["p_orderInfo"].Value); 
                     
                        // DbCommand  checkInventoryCommand = new DbCommand();
                        // checkInventoryCommand.Connection = connection;
                        // checkInventoryCommand.CommandText = 
                        // @"update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";
                        // int retVal = checkInventoryCommand.ExecuteNonQuery();
                        // Console.WriteLine("Rows to be affected by checkInventoryCommand: {0}", retVal);
                     
                        System.Console.WriteLine("order.itemid inventorychecked sendmessage for {0}", order.orderid);
                        Inventory inventory = new Inventory();
                        inventory.inventorylocation = "Philly";
                        inventory.itemid = order.itemid;
                        inventory.orderid = order.orderid;
                        inventory.suggestiveSale = "beer";
                        string inventoryJSON = JsonConvert.SerializeObject(inventory);
                        System.Console.WriteLine("order.itemid inventoryJSON {0}", inventoryJSON);


                        OracleCommand inventorySendMessageCommand = new OracleCommand();
                        inventorySendMessageCommand.Connection = connection;
                        inventorySendMessageCommand.CommandText = "enqueueInventoryMessage";
                        inventorySendMessageCommand.CommandType = CommandType.StoredProcedure;
                        OracleParameter p_inventoryInfoParam = new OracleParameter("p_inventoryInfo", OracleDbType.Varchar2, 32767);
                        p_inventoryInfoParam.Direction = ParameterDirection.Input;

                        p_inventoryInfoParam.Value = inventoryJSON;

                        inventorySendMessageCommand.Parameters.Add(p_inventoryInfoParam);

                        inventorySendMessageCommand.ExecuteNonQuery();
                    }
                }
                catch (NullReferenceException ex)
                {
                    System.Console.WriteLine("Exception: {0}", ex.ToString());
                    return "fail:" + ex;
                }
                connection.Close();
            }
            return "complete";
        }

    }
}
