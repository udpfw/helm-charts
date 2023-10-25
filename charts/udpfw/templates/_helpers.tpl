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
app.kubernetes.io/version: {{ .Values.udpfw.image.tag | default .Chart.AppVersion | quote }}
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
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "udpfw.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "udpfw.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Bind address the server will listen on
*/}}
{{- define "udpfw.bind" -}}
    {{ $defaultPort := (.Values.udpfw.defaultPort | int) }}
    {{- if .Values.udpfw.bindIPV6 }}
        {{- printf "[::]:%d" $defaultPort }}
    {{- else}}
        {{- printf ":%d" $defaultPort }}
    {{- end }}
{{- end -}}

{{/*
PubSub environment variables
*/}}
{{- define "udpfw.pubsub-envs" -}}
    {{- if or (and .Values.nats.enabled .Values.redis.enabled) (and .Values.udpfw.nats.url .Values.udpfw.redis.url)}}
        {{- fail "define either NATS or Redis URL, not both." }}
    {{- end }}
    {{- if (or .Values.udpfw.nats.url .Values.nats.enabled) }}
        {{- include "udpfw.pubsub-envs.nats" . }}
    {{- else if (or .Values.udpfw.redis.url .Values.redis.enabled) }}
        {{- include "udpfw.pubsub-envs.redis" . }}
    {{- else }}
        {{- fail "define either NATS or Redis URL." }}
    {{- end }}
{{- end -}}

{{/*
PubSub NATS environment variables
*/}}
{{- define "udpfw.pubsub-envs.nats" -}}
- name: UDPFW_DISPATCH_NATS_URL
  value: {{ .Values.udpfw.nats.url | default (printf "%s-nats:4222" (include "udpfw.fullname" . )) }}
- name: UDPFW_DISPATCH_NATS_SUBSCRIPTION_SUBJECT
  value: {{ .Values.udpfw.nats.subscriptionSubject | default "udpfw-dispatch-exchange" }}
{{- with .Values.udpfw.nats.userCredentials }}
- name: UDPFW_DISPATCH_NATS_USER_CREDENTIALS_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.udpfw.nats.userCredentialsNkey }}
- name: UDPFW_DISPATCH_NATS_USER_CREDENTIALS_NKEY_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.udpfw.nats.nkeyFromSeed }}
- name: UDPFW_DISPATCH_NATS_NKEY_SEED_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.udpfw.nats.rootCA }}
- name: UDPFW_DISPATCH_NATS_ROOT_CA_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.udpfw.nats.clientCertificate }}
- name: UDPFW_DISPATCH_NATS_CLIENT_CERTIFICATE_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.udpfw.nats.clientKey }}
- name: UDPFW_DISPATCH_NATS_CLIENT_CERTIFICATE_KEY_PATH
  value: {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
PubSub Redis environment variables
*/}}
{{- define "udpfw.pubsub-envs.redis" -}}
- name: UDPFW_DISPATCH_REDIS_PATH
  value: {{ .Values.udpfw.redis.url | default (printf "redis://%s-redis-master:6379/0" (include "udpfw.fullname" . )) }}
- name: UDPFW_DISPATCH_REDIS_PUBSUB_CHANNEL
  value: {{ .Values.udpfw.redis.channel | default "udpfw-dispatch-exchange" }}
{{- end -}}
