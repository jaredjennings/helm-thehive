{{- define "thehive.elasticUserSecretName" -}}
  {{- if .Values.elasticsearch.eck.enabled -}}
    {{- if .Values.elasticsearch.eck.name -}}
      {{ printf "%s-%s" .Values.elasticsearch.eck.name "es-elastic-user" | quote }}
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

{{- define "thehive.elasticURL" -}}
{{- if .Values.elasticsearch.eck.enabled -}}
{{ printf "https://%s-es-http:9200" .Values.elasticsearch.eck.name | quote }}
{{- else -}}{{- /* guess */ -}}
"https://elasticsearch:9200"
{{- end -}}
{{- end }}

{{- define "thehive.elasticCACertSecretName" -}}
{{- if .Values.elasticsearch.eck.enabled -}}
{{- if .Values.elasticsearch.eck.name -}}
{{ printf "%s-%s" (.Values.elasticsearch.eck.name) "es-http-ca-internal" | quote }}
{{- else -}}
{{ fail "CA cert secret: when ECK is enabled you must supply a value for elasticsearch.eck.name." }}
{{- end -}}
{{- else if .Values.elasticsearch.external.enabled -}}
{{ printf "%s-%s" (include "thehive.fullname" .) "external-es-http-ca" | quote }}
{{- else -}}{{- /* with TheHive it is ok to not use Elasticsearch */ -}}
{{- end -}}
{{- end }}