using System;
using System.Collections.Generic;
using System.Linq;

using System.Text;
using System.Data.OracleClient;
using System.Data;

using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
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
        public IEnumerable<Inventory> Get()
        {
            using (OracleConnection objConn = new OracleConnection("User Id=INVENTORYUSER;Password=Welcome12345;Data Source=inventorydb_tp;"))
            {
                Console.WriteLine("objConn:" + objConn);
                OracleCommand objCmd = new OracleCommand();
                objCmd.Connection = objConn;
                objCmd.CommandText = "deqOrdMsg";
                objCmd.CommandType = CommandType.StoredProcedure;
                OracleParameter p_actionParam = new OracleParameter("p_action", OracleDbType.Varchar2);
                p_actionParam.Direction = ParameterDirection.Output;
                //   p_actionParam.Value           = myArrayDeptNo;
                objCmd.Parameters.Add(p_actionParam);
                OracleParameter p_orderidParam = new OracleParameter("p_orderid", OracleDbType.Varchar2);
                p_orderidParam.Direction = ParameterDirection.Output;
                objCmd.Parameters.Add(p_orderidParam);
                try
                {
                    objConn.Open();
                    objCmd.ExecuteNonQuery();
                    System.Console.WriteLine("p_orderid {0}", objCmd.Parameters["p_orderid"].Value);
                }
                catch (Exception ex)
                {
                    System.Console.WriteLine("Exception: {0}", ex.ToString());
                }
                objConn.Close();
            }
            var rng = new Random();
            return Enumerable.Range(1, 5).Select(index => new Inventory
            {
                Date = DateTime.Now.AddDays(index),
                ItemId = 66 + index,
                // rng.Next(-20, 55),
                Summary = Summaries[rng.Next(Summaries.Length)]
            })
            .ToArray();
        }

    }
}
