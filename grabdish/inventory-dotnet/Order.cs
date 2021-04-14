using System;

namespace inventory_dotnet
{
    //  {"orderid":"13","itemid":"sushi","deliverylocation":"780 PANORAMA DR,San Francisco,CA","status":"pending","inventoryLocation":"","suggestiveSale":""}
    public class Order
    {
        public string orderid { get; set; }
        public string itemid { get; set; }
        public string deliverylocation { get; set; }
        public string status { get; set; }
        public string inventoryLocation { get; set; }
        public string suggestiveSale { get; set; }
    }
}
