/*
 ** Copyright (c) 2022 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package oracle.modernappdev;

public class Command {

    public String serviceName; //order, inventory, or supplier
    public String commandName;
    public int orderId = -1;//only applies to placeorder and showorder, all others -1
    public String orderItem = "sushi";
    public String deliverTo = "deliver to test address";

    public Command() {}

}

