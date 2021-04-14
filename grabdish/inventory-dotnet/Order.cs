using System;

namespace inventory_dotnet
{
    //  {"orderid":"13","itemid":"sushi","deliverylocation":"780 PANORAMA DR,San Francisco,CA","status":"pending","inventoryLocation":"","suggestiveSale":""}
    public class Order
    {

        public int orderid { get; set; }
        public int itemid { get; set; }
        public int deliverylocation { get; set; }
        public int status { get; set; }
        public int inventoryLocation { get; set; }
        public int suggestiveSale { get; set; }

        public string Summary { get; set; }
    }
}
