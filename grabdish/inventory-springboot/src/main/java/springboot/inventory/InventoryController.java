package springboot.inventory;


import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
public class InventoryController {
    
    @RequestMapping("/")
    public String index() {
        return "inventory rest test target";
    }
    
}
