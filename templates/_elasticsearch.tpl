{{- define "thehive.elasticUserSecretName" -}}
  {{- if .Values.elasticsearch.eck.enabled -}}
    {{- if .Values.elasticsearch.eck.name -}}
      {{ printf "%s-%s" .Values.elasticsearch.eck.name "es-elastic-user" }}
    {{- else -}}
      {{ fail "While trying to construct user secret name: when elasticsearch.eck.enabled is true, you must provide elasticsearch.eck.name." }}
    {{- end -}}
  {{- else if .Values.elasticsearch.external.enabled -}}
    {{- if .Values.elasticsearch.userSecret -}}
      {{ .Values.elasticsearch.userSecret }}
    {{- else -}}
      {{ fail "When elasticsearch.external.enabled is false, you must provide elasticsearch.userSecret." }}
    {{- end -}}
  {{- else -}}
    {{- /* with TheHive it is ok to not use Elasticsearch */ -}}
  {{- end -}}
{{- end }}


{{- define "thehive.elasticHostname" -}}
{{- if .Values.elasticsearch.eck.enabled -}}
{{ printf "%s-es-http" .Values.elasticsearch.eck.name }}
{{- else -}}
{{ .Values.elasticsearch.hostname | default "elasticsearch" }}
{{- end -}}
{{- end }}


{{- define "thehive.elasticCACertSecretName" -}}
{{- if .Values.elasticsearch.eck.enabled -}}
{{- if .Values.elasticsearch.eck.name -}}
{{ printf "%s-%s" (.Values.elasticsearch.eck.name) "es-http-certs-public" }}
{{- else -}}
{{ fail "CA cert secret: when ECK is enabled you must supply a value for elasticsearch.eck.name." }}
{{- end -}}
{{- else if .Values.elasticsearch.external.enabled -}}
{{ printf "%s-%s" (include "thehive.fullname" .) "external-es-http-ca" | quote }}
{{- else -}}
{{ fail "Elastic CA cert summoned, but Elastic support is not enabled??" }}
{{- end -}}
{{- end }}
