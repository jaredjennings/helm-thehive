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
    secretName: {{ default .Values.elasticsearch.caCertSecret (include "thehive.elasticCACertSecretName" .) }}
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
/etc/cortex/es-trust
{{- end }}
{{- define "thehive.esTrustStore" -}}
{{ printf "%s/store" (include "thehive.esTrustStoreDir" .) }}
{{- end }}
{{- define "thehive.esTrustStoreVolumeMount" -}}
- name: es-trust-store
  mountPath: {{ include "thehive.esTrustStoreDir" . }}
{{- end }}


