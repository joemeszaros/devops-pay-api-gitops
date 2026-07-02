{{- define "pay-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pay-api.fullname" -}}
{{- include "pay-api.name" . -}}
{{- end -}}
