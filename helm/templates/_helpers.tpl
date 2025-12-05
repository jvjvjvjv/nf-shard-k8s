{{/*
Expand the name of the chart.
*/}}
{{- define "nf-shard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "nf-shard.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nf-shard.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nf-shard.labels" -}}
helm.sh/chart: {{ include "nf-shard.chart" . }}
{{ include "nf-shard.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/user: {{ .Values.user.name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nf-shard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nf-shard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nf-shard.serviceAccountName" -}}
{{- if .Values.nextflow.serviceAccount.create }}
{{- default (include "nf-shard.fullname" .) .Values.nextflow.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.nextflow.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace name
*/}}
{{- define "nf-shard.namespace" -}}
{{- if .Values.namespace.name }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Name }}
{{- end }}
{{- end }}
