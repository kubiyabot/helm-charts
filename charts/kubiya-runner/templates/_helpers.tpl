{{/*
Expand the name of the chart.
*/}}
{{- define "kubiya-runner.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubiya-runner.fullname" -}}
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
{{- define "kubiya-runner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubiya-runner.labels" -}}
helm.sh/chart: {{ include "kubiya-runner.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "kubiya-runner.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: {{ template "kubiya-runner.name" . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubiya-runner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubiya-runner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

# ----------------------------------------------
# TODO: remove this?
{{/*
Create the name of the service account to use
*/}}
{{- define "kubiya-runner.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubiya-runner.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "kubiya-runner-common.labels" -}}
helm.sh/chart: {{ include "kubiya-runner.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "kubiya-runner-common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: {{ template "kubiya-runner.name" . }}
{{- end }}
{{- end }}

{{/*
Common Selector labels
*/}}
{{- define "kubiya-runner-common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubiya-runner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Agent Manager labels
*/}}

{{- define "kubiya-runner-agent-manager.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/component: agent-manager
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubiya-runner-agent-manager.selectorLabels" }}
{{ include "kubiya-runner.selectorLabels" . }}
app.kubernetes.io/component: agent-manager
{{- end }}

{{/*
Tool Manager labels
*/}}

{{- define "kubiya-runner-tool-manager.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/component: tool-manager
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubiya-runner-tool-manager.selectorLabels" }}
{{ include "kubiya-runner.selectorLabels" . }}
app.kubernetes.io/component: tool-manager
{{- end }}

{{/*
Kubiya Operator labels
*/}}

{{- define "kubiya-runner-kubiya-operator.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/component: kubiya-operator
{{- end }}

{{/*
Kubiya Operator Selector labels
*/}}
{{- define "kubiya-runner-kubiya-operator.selectorLabels" }}
{{ include "kubiya-runner.selectorLabels" . }}
app.kubernetes.io/component: kubiya-operator
{{- end }}
