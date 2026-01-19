{{/*
Expand the name of the chart.
*/}}
{{- define "background-jobs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "background-jobs.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "background-jobs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "background-jobs.labels" -}}
helm.sh/chart: {{ include "background-jobs.chart" . }}
{{ include "background-jobs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "background-jobs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "background-jobs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "background-jobs.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "background-jobs.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Legacy helpers for backwards compatibility
*/}}
{{- define "temporal-worker.fullname" -}}
{{ include "background-jobs.fullname" . }}
{{- end }}

{{- define "temporal-worker.labels" -}}
{{ include "background-jobs.labels" . }}
{{- end }}

{{- define "temporal-worker.selectorLabels" -}}
{{ include "background-jobs.selectorLabels" . }}
{{- end }}

{{- define "temporal-worker.serviceAccountName" -}}
{{ include "background-jobs.serviceAccountName" . }}
{{- end }}
