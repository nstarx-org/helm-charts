{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
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
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod labels
*/}}
{{- define "app.podLabels" -}}
{{ include "app.selectorLabels" . }}
{{- if .Values.podLabels }}
{{ toYaml .Values.podLabels }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a fully qualified ConfigMap name.
*/}}
{{- define "app.configMapName" -}}
{{- printf "%s-configmap" (include "app.fullname" .) }}
{{- end }}

{{/*
Create a fully qualified Secret name.
*/}}
{{- define "app.secretName" -}}
{{- if .Values.secrets.name }}
{{- .Values.secrets.name }}
{{- else }}
{{- printf "%s-secret" (include "app.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Create a fully qualified PVC name.
*/}}
{{- define "app.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "%s-pvc" (include "app.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Create a fully qualified PV name.
*/}}
{{- define "app.pvName" -}}
{{- printf "%s-pv" (include "app.fullname" .) }}
{{- end }}

{{/*
Create the fully qualified service name (with namespace and cluster domain)
*/}}
{{- define "app.serviceFqdn" -}}
{{- printf "%s.%s.svc.%s" (include "app.fullname" .) .Release.Namespace (default "cluster.local" .Values.clusterDomain) }}
{{- end }}

{{/*
Create service name (without namespace) for in-cluster references
*/}}
{{- define "app.serviceName" -}}
{{- include "app.fullname" . }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress
*/}}
{{- define "app.ingress.apiVersion" -}}
{{- if .Values.ingress.apiVersion -}}
{{- .Values.ingress.apiVersion -}}
{{- else if semverCompare ">=1.19-0" .Capabilities.KubeVersion.Version -}}
{{- print "networking.k8s.io/v1" -}}
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.Version -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Return if ingress supports pathType
*/}}
{{- define "app.ingress.supportsPathType" -}}
{{- or (eq (include "app.ingress.apiVersion" .) "networking.k8s.io/v1") (eq (include "app.ingress.apiVersion" .) "networking.k8s.io/v1beta1") -}}
{{- end -}}

{{/*
Return ingress path type
*/}}
{{- define "app.ingress.pathType" -}}
{{- if .Values.ingress.pathType -}}
{{- .Values.ingress.pathType -}}
{{- else -}}
{{- if eq (include "app.ingress.supportsPathType" .) "true" -}}
{{- print "Prefix" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required for TLS
*/}}
{{- define "app.ingress.certManager" -}}
{{- if .Values.ingress.tls -}}
{{- if .Values.ingress.certManager -}}
{{- printf "true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return which ingress class to use
*/}}
{{- define "app.ingress.class" -}}
{{- if .Values.ingress.className -}}
{{- printf "ingressClassName: %s" .Values.ingress.className -}}
{{- else if .Values.ingress.ingressClassName -}}
{{- printf "ingressClassName: %s" .Values.ingress.ingressClassName -}}
{{- else -}}
{{- printf "kubernetes.io/ingress.class: %s" (default "nginx" .Values.ingress.class) -}}
{{- end -}}
{{- end -}}

{{/*
Return the container port
*/}}
{{- define "app.containerPort" -}}
{{- if .Values.service.targetPort -}}
{{- .Values.service.targetPort -}}
{{- else -}}
{{- .Values.service.port -}}
{{- end -}}
{{- end -}}

{{/*
Get Ingress URL
*/}}
{{- define "app.ingressUrl" -}}
{{- if .Values.ingress.enabled }}
{{- range $host := .Values.ingress.hosts }}
{{- range .paths }}
{{- $protocol := "http" }}
{{- if $.Values.ingress.tls }}
{{- $protocol = "https" }}
{{- end }}
{{- printf "%s://%s%s" $protocol $host.host .path }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate basic auth credentials
*/}}
{{- define "app.basicAuthCredentials" -}}
{{- $username := default (randAlphaNum 8) .Values.basicAuth.username }}
{{- $password := default (randAlphaNum 16) .Values.basicAuth.password }}
{{- $credentials := htpasswd $username $password }}
{{- printf "%s" $credentials -}}
{{- end }}

{{/*
Determine if we should use HorizontalPodAutoscaler v2 or v2beta2
*/}}
{{- define "app.hpa.apiVersion" -}}
{{- if semverCompare ">=1.23-0" .Capabilities.KubeVersion.Version -}}
{{- print "autoscaling/v2" -}}
{{- else -}}
{{- print "autoscaling/v2beta2" -}}
{{- end -}}
{{- end }}