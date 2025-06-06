{{/*
Expand the name of the chart.
*/}}
{{- define "kubiya-runner.name" -}}
{{- if .Values.runnerNameOverride -}}
{{- .Values.runnerNameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kubiya-runner.fullname" -}}
{{- if .Values.runnerNameOverride -}}
{{- .Values.runnerNameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubiya-runner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
# Formats imagePullSecrets. Input is (dict "Values" .Values "imagePullSecrets" .{specific imagePullSecrets})
*/}}
{{- define "kubiya-runner.imagePullSecrets" -}}
{{- range (concat .Values.imagePullSecrets .imagePullSecrets) }}
  {{- if eq (typeOf .) "map[string]interface {}" }}
- {{ toYaml . | trim }}
  {{- else }}
- name: {{ . }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "kubiya-runner-common.labels" -}}
helm.sh/chart: {{ include "kubiya-runner.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "kubiya-runner-common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: {{ template "kubiya-runner.fullname" . }}
{{- end }}
{{- end }}

{{/*
Common Selector labels
*/}}
{{- define "kubiya-runner-common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubiya-runner.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Agent Manager labels
*/}}
{{- define "agent-manager.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/kubiya-runner-component: agent-manager
{{- end }}

{{/*
Agent Manager Selector labels
*/}}
{{- define "agent-manager.selectorLabels" }}
{{ include "kubiya-runner-common.selectorLabels" . }}
app.kubernetes.io/kubiya-runner-component: agent-manager
{{- end }}

{{/*
Tool Manager labels
*/}}
{{- define "tool-manager.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/kubiya-runner-component: tool-manager
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tool-manager.selectorLabels" }}
{{ include "kubiya-runner-common.selectorLabels" . }}
app.kubernetes.io/kubiya-runner-component: tool-manager
{{- end }}

{{/*
Workflow Engine labels
*/}}
{{- define "workflow-engine.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/kubiya-runner-component: workflow-engine
{{- end }}

{{/*
Workflow Engine Selector labels
*/}}
{{- define "workflow-engine.selectorLabels" }}
{{ include "kubiya-runner-common.selectorLabels" . }}
app.kubernetes.io/kubiya-runner-component: workflow-engine
{{- end }}

{{/*
Kubiya Operator labels
*/}}
{{- define "kubiya-operator.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/kubiya-runner-component: kubiya-operator
{{- end }}

{{/*
Kubiya Operator Selector labels
*/}}
{{- define "kubiya-operator.selectorLabels" }}
{{ include "kubiya-runner-common.selectorLabels" . }}
app.kubernetes.io/kubiya-runner-component: kubiya-operator
{{- end }}

{{/*
Kubiya Operator labels
*/}}
{{- define "image-updater.labels" }}
{{ include "kubiya-runner-common.labels" . }}
app.kubernetes.io/kubiya-runner-component: image-updater
{{- end }}

{{/*
Kubiya Operator Selector labels
*/}}
{{- define "image-updater.selectorLabels" }}
{{ include "kubiya-runner-common.selectorLabels" . }}
app.kubernetes.io/kubiya-runner-component: image-updater
{{- end }}


# Service Accounts names for all kubiya runner components.
# If create is set to true, name of the service account is value of .name, or, if .name not provided will be set to component name.
{{- define "kubiya-runner.serviceAccountName.operator" -}}
{{- if .Values.kubiyaOperator.serviceAccount.create }}
{{- default (printf "%s-operator" (include "kubiya-runner.name" .)) .Values.kubiyaOperator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.kubiyaOperator.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "kubiya-runner.serviceAccountName.toolManager" -}}
{{- if .Values.toolManager.serviceAccount.create }}
{{- default (printf "%s-tool-manager" (include "kubiya-runner.name" .)) .Values.toolManager.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.toolManager.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "kubiya-runner.serviceAccountName.workflowEngine" -}}
{{- if .Values.workflowEngine.serviceAccount.create }}
{{- default (printf "%s-workflow-engine" (include "kubiya-runner.name" .)) .Values.workflowEngine.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.workflowEngine.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "kubiya-runner.serviceAccountName.agentManager" -}}
{{- if .Values.agentManager.serviceAccount.create }}
{{- default (printf "%s-agent-manager" (include "kubiya-runner.name" .)) .Values.agentManager.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.agentManager.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "kubiya-runner.serviceAccountName.imageUpdater" -}}
{{- if .Values.imageUpdater.serviceAccount.create }}
{{- default (printf "%s-image-updater" (include "kubiya-runner.name" .)) .Values.imageUpdater.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.imageUpdater.serviceAccount.name }}
{{- end }}
{{- end }}
