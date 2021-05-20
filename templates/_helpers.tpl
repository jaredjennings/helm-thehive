{{/*
Expand the name of the chart.
*/}}
{{- define "thehive.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "thehive.fullname" -}}
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
Create the name of Cassandra, because it looks like scoping issues prevent us
from using its original definition.
*/}}
{{- define "thehive.cassandra.fullname" -}}
{{- if .Values.cassandra.fullnameOverride }}
{{- .Values.cassandra.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := "cassandra" }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}


{{- define "thehive.cassandra.secretname" -}}
{{ include "thehive.cassandra.fullname" . }}
{{- end }}


{{/*
Name the Play framework secret.
*/}}
{{- define "thehive.playsecretname" -}}
{{ include "thehive.fullname" . -}} -play-secret
{{- end }}

{{/*
Name the extra config secret
*/}}
{{- define "thehive.extraconfigsecret" -}}
{{ include "thehive.fullname" . -}} -extra-config
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "thehive.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "thehive.labels" -}}
helm.sh/chart: {{ include "thehive.chart" . }}
{{ include "thehive.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "thehive.selectorLabels" -}}
app.kubernetes.io/name: {{ include "thehive.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "thehive.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "thehive.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "thehive.localIndexPVCName" -}}
{{ printf "%s-%s" (include "thehive.fullname" .) "local-index" | quote }}
{{- end }}
{{- define "thehive.localDatabasePVCName" -}}
{{ printf "%s-%s" (include "thehive.fullname" .) "local-db" | quote }}
{{- end }}
{{- define "thehive.attachmentPVCName" -}}
{{ printf "%s-%s" (include "thehive.fullname" .) "attachments" | quote }}
{{- end }}

{{- define "thehive.templatesConfigMapName" -}}
{{ printf "%s-etc-th-tmpl" (include "thehive.fullname" .) }}
{{- end }}