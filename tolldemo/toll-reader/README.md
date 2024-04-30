# Toll Reader Simulator

## Description

This application simualates a toll reader. It takes 1 parameter; sleep time betwen record generation. Default is 1000 ms (1 sec).

**NOTE:** the program will not stup until you kill it!

This example will generate a record each 500 ms (after DB warmup)

```shell
target/toll-reader.output/default/toll-reader 500
```

## Native Compile

To compile the application execute the following command:

```shell
mvn clean -Pnative native:compile -DskipTests
```

This will build a native image optimized for the build platform (requires the previous step):

```shell
native-image --bundle-apply=target/toll-reader.nib -march=native
```

## Record format

The application created records in a TXEventQ with the following JSON format.

```json
{
  "accountnumber": 55468,
  "license-plate": "FL-69540",
  "cartype": "SUV",
  "tagid": 87967,
  "timestamp": "2024-04-18"
}
```
