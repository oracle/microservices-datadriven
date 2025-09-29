# OBaas Sample App Chart 

This chart provides an extensible sample for applications running on [OBaaS](https://oracle.github.io/microservices-datadriven/obaas/).

To use this chart for a given application, download the chart and update the [Chart.name](./Chart.yaml) value to your application's name.

## Customizing the chart

The OBaaS sample app chart is meant to serve as a developer template, and is fully customizable.

Standard parameters for Kubernetes options like node affinity, HPAs, ingress and more are provided in the [values.yaml file](./values.yaml).

#### OBaaS options

Within the [values.yaml file](./values.yaml), the `obaas` key allows chart developers to enable or disable OBaaS integrations like database connectivity, OpenTelemetry, MicroProfile LRA, SpringBoot, and Eureka.
enabled: true
