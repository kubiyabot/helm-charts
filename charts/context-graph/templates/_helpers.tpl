{{/*
Expand the name of the chart.
*/}}
{{- define "context-graph.name" -}}
{{- default .Chart.Name .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "context-graph.fullname" -}}
{{- if .Values.name }}
{{- .Values.name | trunc 63 | trimSuffix "-" }}
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
{{- define "context-graph.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "context-graph.labels" -}}
helm.sh/chart: {{ include "context-graph.chart" . }}
{{ include "context-graph.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "context-graph.selectorLabels" -}}
app.kubernetes.io/name: {{ include "context-graph.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "context-graph.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "context-graph.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
API-specific helpers (for backwards compatibility)
*/}}
{{- define "context-graph-api.name" -}}
{{ include "context-graph.name" . }}
{{- end }}

{{- define "context-graph-api.fullname" -}}
{{ include "context-graph.fullname" . }}
{{- end }}

{{- define "context-graph-api.labels" -}}
{{ include "context-graph.labels" . }}
{{- end }}
