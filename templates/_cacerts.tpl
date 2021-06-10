{{- define "thehive.esCACertDir" -}}
/tmp/es-http-ca
{{- end }}


{{- define "thehive.esCACert" -}}
{{ printf "%s/ca.crt" (include "thehive.esCACertDir" .) }}
{{- end }}


{{- define "thehive.esCACertVolumes" -}}
{{- if .Values.elasticsearch.tls }}
- name: es-http-ca
  secret:
    secretName: {{ .Values.elasticsearch.caCertSecret | default (include "thehive.elasticCACertSecretName" .) }}
    items:
      - key: {{ .Values.elasticsearch.caCertSecretMappingKey | quote }}
        path: "ca.crt"
{{- end }}
{{- end }}


{{- define "thehive.esCACertVolumeMounts" -}}
- name: es-http-ca
  mountPath: {{ include "thehive.esCACertDir" . | quote }}
{{- end }}


{{/*
Container-local path for JKS-format Elasticsearch trust store.
This is JKS-format because elastic4play requires a keyStore to be
provided in order for the trustStore setting to take effect, and a
trust store can serve as an empty keystore too. This will need to be
changed if Elasticsearch client certs are ever supported.
*/}}
{{- define "thehive.esTrustStoreDir" -}}
/etc/thehive/es-trust
{{- end }}


{{- define "thehive.esTrustStore" -}}
{{ printf "%s/store" (include "thehive.esTrustStoreDir" .) }}
{{- end }}


{{- define "thehive.esTrustStoreVolume" -}}
- name: es-trust-store
  emptyDir: {}
{{- end }}


{{- define "thehive.esTrustStoreVolumeMount" -}}
- name: es-trust-store
  mountPath: {{ include "thehive.esTrustStoreDir" . }}
{{- end }}



{{- define "thehive.wsCACertVolumes" -}}
{{- range .Values.trustRootCertsInSecrets }}
{{- $name := printf "tls-ca-s-%s" . }}
- name: {{ $name | quote }}
  secret:
    secretName: {{ . | quote }}
    items:
      - key: "ca.crt"
        path: "ca.crt"
{{- end }}
{{- range .Values.trustRootCerts }}
{{- $shortsum := . | sha256sum | substr 0 10 }}
{{- $name := printf "tls-ca-%s" $shortsum }}
- name: {{ $name | quote }}
  secret:
    secretName: {{ printf "%s-ca-%s" (include "thehive.fullname" $) $shortsum | quote }}
    items:
      - key: "ca.crt"
        path: "ca.crt"
{{- end }}
{{- end }}


{{- define "thehive.wsCACertVolumeMounts" -}}
{{- range .Values.trustRootCertsInSecrets }}
{{ $name := printf "tls-ca-s-%s" . }}
- name: {{ $name | quote }}
  mountPath: {{ printf "/etc/cortex/tls/%s" $name | quote }}
{{- end }}
{{- range .Values.trustRootCerts }}
{{- $shortsum := . | sha256sum | substr 0 10 }}
{{- $name := printf "tls-ca-%s" $shortsum }}
- name: {{ $name | quote }}
  mountPath: {{ printf "/etc/cortex/tls/%s" $name | quote }}
{{- end }}
{{- end }}


{{- define "thehive.wsCACertFilenamesPlayWSStoreLines" }}
{{- range .Values.trustRootCertsInSecrets }}
{{ $name := printf "tls-ca-s-%s" . }}
{{ printf "{ path: \"/etc/cortex/tls/%s/ca.crt\", type: \"PEM\" }" $name }}
{{- end }}
{{- range .Values.trustRootCerts }}
{{- $shortsum := . | sha256sum | substr 0 10 }}
{{- $name := printf "tls-ca-%s" $shortsum }}
{{ printf "{ path: \"/etc/cortex/tls/%s/ca.crt\", type: \"PEM\" }" $name }}
{{- end }}
{{- end }}

{{- define "thehive.wsConfigRoot" -}}
{{- if hasPrefix "3." .Values.image.tag -}}
ws
{{- else -}}
play.ws
{{- end -}}
{{- end -}}

{{- define "thehive.wsCACertPlayWSConfig" -}}
{{- if (or .Values.trustRootCerts .Values.trustRootCertsInSecrets) }}
{{ include "thehive.wsConfigRoot" }}.ssl.trustManager.stores = [
{{- include "thehive.wsCACertFilenamesPlayWSStoreLines" . | nindent 2 }}
]
{{- end }}
{{- end }}
