using System;
using System.Collections.Generic;
using System.Linq;
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
                //https://www.oracle.com/database/technologies/appdev/dotnet/odp.html
                //dotnet add package Oracle.ManagedDataAccess.Core --version 3.21.1
                string conString = "User Id=<user>;Password=<password>;Data Source=<data source>;";
                OracleConnection con = new OracleConnection();
                con.ConnectionString = conString;
                con.Open();
                OracleCommand cmd = con.CreateCommand();
                cmd.CommandText = "INSERT INTO j_order (po_document) VALUES (:1)";
                OracleParameter param = new OracleParameter();
                param.OracleDbType = OracleDbType.Varchar2;
                param.Value = @"{'id': 66,'name': 'sushi', 'location': 'Philadelphia'}";
                cmd.Parameters.Add(param);
                cmd.ExecuteNonQuery();
                Console.WriteLine("JSON inserted.");
                Console.WriteLine();
                cmd.CommandText =  "SELECT po_document FROM j_order WHERE JSON_EXISTS (po_document, '$.location')";
                OracleDataReader rdr = cmd.ExecuteReader();
                rdr.Read();
                Console.WriteLine(rdr.GetOracleValue(0));
            var rng = new Random();
            return Enumerable.Range(1, 5).Select(index => new Inventory
            {
                Date = DateTime.Now.AddDays(index),
                TemperatureC = rng.Next(-20, 55),
                Summary = Summaries[rng.Next(Summaries.Length)]
            })
            .ToArray();
        }
    }
}
