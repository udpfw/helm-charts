{{/*
Expand the name of the chart.
*/}}
{{- define "udpfw.dispatch.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "udpfw.dispatch.fullname" -}}
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
{{- define "udpfw.dispatch.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "udpfw.dispatch.labels" -}}
helm.sh/chart: {{ include "udpfw.dispatch.chart" . }}
{{ include "udpfw.dispatch.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.dispatch.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: udpfw
{{- with .Values.global.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "udpfw.dispatch.selectorLabels" -}}
app.kubernetes.io/name: {{ include "udpfw.dispatch.name" . }}
app.kubernetes.io/component: dispatch
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the dispatch service account to use
*/}}
{{- define "udpfw.dispatch.serviceAccountName" -}}
{{- if .Values.dispatch.serviceAccount.create }}
{{- default (include "udpfw.dispatch.fullname" . ) .Values.dispatch.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.dispatch.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Bind address the server will listen on
*/}}
{{- define "udpfw.dispatch.bind" -}}
    {{ $defaultPort := (.Values.dispatch.container.defaultPort | int) }}
    {{- if .Values.dispatch.container.bindIPV6 }}
        {{- printf "[::]:%d" $defaultPort }}
    {{- else}}
        {{- printf ":%d" $defaultPort }}
    {{- end }}
{{- end -}}

{{/*
Dispatch PubSub environment variables
*/}}
{{- define "udpfw.dispatch.pubsub-envs" -}}
    {{- if or (and .Values.nats.enabled .Values.redis.enabled) (and .Values.dispatch.container.nats.url .Values.dispatch.container.redis.url)}}
        {{- fail "dispatch: define either NATS or Redis URL, not both." }}
    {{- end }}
    {{- if (or .Values.dispatch.container.nats.url .Values.nats.enabled) }}
        {{- include "udpfw.dispatch.pubsub-envs.nats" . }}
    {{- else if (or .Values.dispatch.container.redis.url .Values.redis.enabled) }}
        {{- include "udpfw.dispatch.pubsub-envs.redis" . }}
    {{- else }}
        {{- fail "dispatch: define either NATS or Redis URL." }}
    {{- end }}
{{- end -}}

{{/*
Dispatch PubSub NATS environment variables
*/}}
{{- define "udpfw.dispatch.pubsub-envs.nats" -}}
- name: UDPFW_DISPATCH_NATS_URL
  value: {{ .Values.dispatch.container.nats.url | default (printf "%s-nats:4222" .Release.Name)  }}
- name: UDPFW_DISPATCH_NATS_SUBSCRIPTION_SUBJECT
  value: {{ .Values.dispatch.container.nats.subscriptionSubject | default "udpfw-dispatch-exchange" }}
{{- with .Values.dispatch.container.nats.userCredentials }}
- name: UDPFW_DISPATCH_NATS_USER_CREDENTIALS_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.dispatch.container.nats.userCredentialsNkey }}
- name: UDPFW_DISPATCH_NATS_USER_CREDENTIALS_NKEY_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.dispatch.container.nats.nkeyFromSeed }}
- name: UDPFW_DISPATCH_NATS_NKEY_SEED_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.dispatch.container.nats.rootCA }}
- name: UDPFW_DISPATCH_NATS_ROOT_CA_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.dispatch.container.nats.clientCertificate }}
- name: UDPFW_DISPATCH_NATS_CLIENT_CERTIFICATE_PATH
  value: {{ . | quote }}
{{- end }}
{{- with .Values.dispatch.container.nats.clientKey }}
- name: UDPFW_DISPATCH_NATS_CLIENT_CERTIFICATE_KEY_PATH
  value: {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
Dispatch PubSub Redis environment variables
*/}}
{{- define "udpfw.dispatch.pubsub-envs.redis" -}}
- name: UDPFW_DISPATCH_REDIS_URL
  value: {{ .Values.dispatch.container.redis.url | default (printf "redis://%s-redis-master:6379/0" .Release.Name) }}
- name: UDPFW_DISPATCH_REDIS_PUBSUB_CHANNEL
  value: {{ .Values.dispatch.container.redis.channel | default "udpfw-dispatch-exchange" }}
{{- end -}}
