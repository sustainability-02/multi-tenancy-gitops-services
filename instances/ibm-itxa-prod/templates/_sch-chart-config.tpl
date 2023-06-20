# Licensed Materials - Property of IBM
# IBM Transformation Extender Advanced (5724-Q23)
# (C) Copyright IBM Corp. 2021, 2022 All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

{{- /*
Chart specific config file for SCH (Shared Configurable Helpers)

_sch-chart-config.tpl is a config file for the chart to specify additional 
values and/or override values defined in the sch/_config.tpl file.
 
*/ -}}

{{- /*
"sch.chart.config.values" contains the chart specific values used to override or provide
additional configuration values used by the Shared Configurable Helpers.
*/ -}}
{{- define "itxa-chart.sch.chart.config.values" -}}
sch:
  chart:
    appName: {{ template "itxa-chart.fullname" . }}
    version: {{ .Chart.Version }}
    fullName: {{ .Chart.Name }}-{{ .Chart.Version }}
    labelType: "prefixed"
    metering:
      productName: {{ template "itxa-chart.metering.prodname" . }}
      productID: {{ template "itxa-chart.metering.prodid" . }}
      productVersion: {{ template "itxa-chart.metering.prodversion" . }}
      productMetric: {{ template "itxa-chart.metering.prodmetric" . }}
      productChargedContainers: {{ template "itxa-chart.metering.prodchargedcontainers" . }}
{{- end -}}