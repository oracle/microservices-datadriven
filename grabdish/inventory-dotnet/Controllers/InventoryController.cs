using System;
using System.Collections.Generic;
using System.Linq;

using System.Text;
using System.Data.OracleClient;
using System.Data;

using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Oracle.ManagedDataAccess.Client;

namespace inventory_dotnet.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class InventoryController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Sushi", "Pizza", "Burger"
        };

        private readonly ILogger<InventoryController> _logger;

        public InventoryController(ILogger<InventoryController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        // public IEnumerable<Inventory> Get()
        public String Get()
        {
            using (OracleConnection connection = 
                new OracleConnection("User Id=INVENTORYUSER;Password=" + Environment.GetEnvironmentVariable("dbpassword") + ";Data Source=inventorydb_tp;"))
            { 
                OracleConfiguration.WalletLocation = Environment.GetEnvironmentVariable("TNS_ADMIN"); // "/Users/pparkins/Downloads/Wallet_INVENTORYDB";
                Console.WriteLine("OracleConfiguration.WalletLocation:" + OracleConfiguration.WalletLocation);
                Console.WriteLine("connection:" + connection);
                OracleCommand objCmd = new OracleCommand();
                objCmd.Connection = connection;
                objCmd.CommandText = "deqOrdMsg";
                objCmd.CommandType = CommandType.StoredProcedure;
                OracleParameter p_orderInfoParam = new OracleParameter("p_orderInfo", OracleDbType.Varchar2);
                p_orderInfoParam.Direction = ParameterDirection.Output;
                objCmd.Parameters.Add(p_orderInfoParam);
/**
                OracleParameter p_actionParam = new OracleParameter("p_action", OracleDbType.Varchar2);
                p_actionParam.Direction = ParameterDirection.Output;
                //   p_actionParam.Value           = myArrayDeptNo;
                objCmd.Parameters.Add(p_actionParam);
                OracleParameter p_orderidParam = new OracleParameter("p_orderid", OracleDbType.Varchar2);
                p_orderidParam.Direction = ParameterDirection.Output;
                objCmd.Parameters.Add(p_orderidParam);
*/
                try
                {
                    connection.Open();
                    objCmd.ExecuteNonQuery();
                    System.Console.WriteLine("p_orderInfo {0}", objCmd.Parameters["p_orderInfo"].Value);
                    Order order = JsonConvert.DeserializeObject<Order>("{}");
                }
                catch (Exception ex)
                {
                    System.Console.WriteLine("Exception: {0}", ex.ToString());
                    return "fail:" + ex;
                }
                connection.Close();
            }
            var rng = new Random();
            return "complete";
        }

    }
}
