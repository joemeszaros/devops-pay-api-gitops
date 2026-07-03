{{- define "currency-exchange.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "currency-exchange.fullname" -}}
{{- printf "%s" (include "currency-exchange.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
