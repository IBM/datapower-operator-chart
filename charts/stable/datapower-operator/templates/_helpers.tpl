{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "datapower-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "datapower-operator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a namespaced name for a release.
The order of naming is release-namespace-chartname
*/}}
{{- define "datapower-operator.namespacedname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name .Release.Namespace $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "datapower-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "datapower-operator.labels" -}}
helm.sh/chart: {{ include "datapower-operator.chart" . }}
{{ include "datapower-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "datapower-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "datapower-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "datapower-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "datapower-operator.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
datapower-operator.getMulti
This template builds a CSV of namespaces from the list watchNamespaces.
Resulting CSV has a trailing ',' that must be removed.
*/}}
{{- define "datapower-operator.getMulti" -}}
{{- range .Values.operator.watchNamespaces -}}{{ . }},{{- end -}}
{{- end -}}

{{/*
datapower-operator.getWatchNamespace
Handle building the WATCH_NAMESPACE environment variable.
WATCH_NAMESPACE is informed by a scope type and a list of namespaces.
*/}}
{{- define "datapower-operator.getWatchNamespace" -}}
{{- if eq .Values.operator.installMode "OwnNamespace" -}}
valueFrom:
  fieldRef:
    fieldPath: metadata.namespace
{{- else if eq .Values.operator.installMode "SingleNamespace" -}}
value: "{{ index .Values.operator.watchNamespaces 0 }}"
{{- else if eq .Values.operator.installMode "MultiNamespace" -}}
value: "{{ include "datapower-operator.getMulti" . | trimSuffix "," }}"
{{- else if eq .Values.operator.installMode "AllNamespaces" -}}
value: ""
{{- end -}}
{{- end -}}

