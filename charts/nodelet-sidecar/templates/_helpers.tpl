{{/*
Expand the name of the chart.
*/}}
{{- define "udpfw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "udpfw.fullname" -}}
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
{{- define "udpfw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "udpfw.labels" -}}
helm.sh/chart: {{ include "udpfw.chart" . }}
{{ include "udpfw.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.nodelet.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: udpfw
{{- with .Values.global.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "udpfw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "udpfw.name" . }}
app.kubernetes.io/component: nodelet
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the nodelet service account to use
*/}}
{{- define "udpfw.nodelet.serviceAccountName" -}}
{{- if .Values.nodelet.serviceAccount.create }}
{{- default (include "udpfw.fullname" . ) .Values.nodelet.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.nodelet.serviceAccount.name }}
{{- end }}
{{- end }}
