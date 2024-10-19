{{/*
Expand the name of the chart.
*/}}
{{- define "helm.chartName" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.chartNameOverride }}
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
{{- define "helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Chart labels
*/}}
{{- define "helm.chartLabels" }}
helm.sh/chart: {{ include "helm.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ include "helm.fullname" . }}
{{- include "helm.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm.selectorLabels" }}
app.kubernetes.io/name: {{ include "helm.chartName" . }}
app.kubernetes.io/instance: {{ include "helm.fullname" . }}
{{- end }}

{{/*
Merge labels
*/}}
{{- define "helm.labels" -}}
{{- $chartLabels := include "helm.chartLabels" . | fromYaml }}
{{- $selectorLabels := include "helm.selectorLabels" . | fromYaml }}
{{- $globalLabels := .Values.global.labels | default dict }}
{{- $combinedLabels := merge $chartLabels $selectorLabels $globalLabels }}
{{- toYaml $combinedLabels }}
{{- end }}

{{/*
Merge Annotations
*/}}
{{- define "helm.annotations" -}}
{{- $globalLabels := .Values.global.annotations | default dict }}
{{- $combinedLabels := merge $globalLabels }}
{{- toYaml $combinedLabels }}
{{- end }}
