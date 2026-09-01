{{/*
Deployment template for dms-order-service
*/}}
{{- define "dms-order-service.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "dms-order-service.fullname" . }}
  labels:
    {{- include "dms-order-service.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "dms-order-service.selectorLabels" . | nindent 6 }}
  strategy:
    type: {{ .Values.strategy.type }}
    {{- if eq .Values.strategy.type "RollingUpdate" }}
    rollingUpdate:
      maxSurge: {{ .Values.strategy.rollingUpdate.maxSurge }}
      maxUnavailable: {{ .Values.strategy.rollingUpdate.maxUnavailable }}
    {{- end }}
  template:
    metadata:
      annotations:
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "dms-order-service.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "dms-order-service.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          env:
            - name: APP_ENV
              value: {{ .Values.env.APP_ENV | quote }}
            - name: LOG_LEVEL
              value: {{ .Values.env.LOG_LEVEL | quote }}
            - name: HTTP_PORT
              value: {{ .Values.env.HTTP_PORT | quote }}
            - name: GIN_MODE
              value: {{ .Values.env.GIN_MODE | quote }}
            {{- if .Values.database.host }}
            - name: DB_HOST
              value: {{ .Values.database.host | quote }}
            {{- end }}
            {{- if .Values.database.port }}
            - name: DB_PORT
              value: {{ .Values.database.port | quote }}
            {{- end }}
            {{- if .Values.database.name }}
            - name: DB_NAME
              value: {{ .Values.database.name | quote }}
            {{- end }}
            {{- if .Values.database.user }}
            - name: DB_USER
              value: {{ .Values.database.user | quote }}
            {{- end }}
            {{- if .Values.database.password }}
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "dms-order-service.fullname" . }}-db-secret
                  key: password
            {{- end }}
            {{- if .Values.redis.host }}
            - name: REDIS_HOST
              value: {{ .Values.redis.host | quote }}
            {{- end }}
            {{- if .Values.redis.port }}
            - name: REDIS_PORT
              value: {{ .Values.redis.port | quote }}
            {{- end }}
            {{- if .Values.redis.password }}
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "dms-order-service.fullname" . }}-redis-secret
                  key: password
            {{- end }}
            {{- if .Values.kafka.brokers }}
            - name: KAFKA_BROKERS
              value: {{ .Values.kafka.brokers | quote }}
            {{- end }}
            {{- if .Values.rateLimit.requestsPerMinute }}
            - name: RATE_LIMIT_RPM
              value: {{ .Values.rateLimit.requestsPerMinute | quote }}
            {{- end }}
            {{- if .Values.sentry.enabled }}
            - name: SENTRY_DSN
              valueFrom:
                secretKeyRef:
                  name: {{ include "dms-order-service.fullname" . }}-sentry-secret
                  key: dsn
            {{- end }}
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          {{- if .Values.monitoring.enabled }}
          - name: METRICS_ENABLED
            value: "true"
          {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}