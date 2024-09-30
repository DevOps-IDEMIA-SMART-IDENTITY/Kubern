{{- define "keepcoding-app.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{- define "keepcoding-app.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

{{- define "keepcoding-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keepcoding-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "keepcoding-app.mariadbSelectorLabels" -}}
app.kubernetes.io/name: {{ include "keepcoding-app.name" . }}-mariadb
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "keepcoding-app.labels" -}}
{{ include "keepcoding-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "keepcoding-app.mariadbLabels" -}}
{{ include "keepcoding-app.mariadbSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}