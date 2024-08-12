+++
archetype = "page"
title = "Learn about the scenario"
weight = 2
+++

In the previous lab, you created an Account service that includes endpoints to create and query accounts, lookup accounts for a given customer, and so on.  In this module you will extend that service to add some new endpoints to allow recording bank transactions, in this case check deposits, in the account journal.

In this lab, we will assume that customers can deposit a check at an Automated Teller Machine (ATM) by typing in the check amount, placing the check into a deposit envelope and then inserting that envelope into the ATM.  When this occurs, the ATM will send a "deposit" message with details of the check deposit.  You will record this as a "pending" deposit in the account journal.

![Deposit check](../images/deposit-check.png " ")

Later, imagine that the deposit envelop arrives at a back office check processing facility where a person checks the details are correct, and then "clears" the check.  When this occurs, a "clearance" message will be sent.  Upon receiving this message, you will change the "pending" transaction to a finalized "deposit" in the account journal.

![Back office check clearing](../images/clearances.png " ")

You will implement this using three microservices:

* The Account service you created in the previous module will have the endpoints to manipulate journal entries
* A new "Check Processing" service will listen for messages and process them by calling the appropriate endpoints on the Account service
* A "Test Runner" service will simulate the ATM and the back office and allow you to send the "deposit" and "clearance" messages to test your other services

![The Check service](../images/check-service.png " ")

