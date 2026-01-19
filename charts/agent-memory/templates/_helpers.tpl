{{/*
Expand the name of the chart.
*/}}
{{- define "agent-memory.name" -}}
{{- default .Chart.Name .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "agent-memory.fullname" -}}
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
{{- define "agent-memory.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agent-memory.labels" -}}
helm.sh/chart: {{ include "agent-memory.chart" . }}
{{ include "agent-memory.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agent-memory.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agent-memory.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "agent-memory.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "agent-memory.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Legacy helpers for backwards compatibility
*/}}
{{- define "context-graph.name" -}}
{{ include "agent-memory.name" . }}
{{- end }}

{{- define "context-graph.fullname" -}}
{{ include "agent-memory.fullname" . }}
{{- end }}

{{- define "context-graph.labels" -}}
{{ include "agent-memory.labels" . }}
{{- end }}

{{- define "context-graph.selectorLabels" -}}
{{ include "agent-memory.selectorLabels" . }}
{{- end }}

{{- define "context-graph.serviceAccountName" -}}
{{ include "agent-memory.serviceAccountName" . }}
{{- end }}

{{/*
API-specific helpers (for backwards compatibility)
*/}}
{{- define "context-graph-api.name" -}}
{{ include "agent-memory.name" . }}
{{- end }}

{{- define "context-graph-api.fullname" -}}
{{ include "agent-memory.fullname" . }}
{{- end }}

{{- define "context-graph-api.labels" -}}
{{ include "agent-memory.labels" . }}
{{- end }}
