---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
    env: {{env}}
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  replicas: 3
  selector:
    matchLabels:
      app: web
      env: {{env}}
  template:
    metadata:
      labels:
        app: web
        env: {{env}}
    spec:
      containers:
      - name: web
        image: {{web_image}}
        imagePullPolicy: Always
        env:
        - name: PORT
          value: "8080"
        - name: API_HOST
          value: "http://api-service:3000"
        ports:
        - containerPort: 8080

---
apiVersion: v1
kind: Service
metadata:
    name: web-service
    labels:
      app: web
      env: {{env}}
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-internal: "false"
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "{{acm_cert_arn}}"
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
      service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS-1-2-2017-01"
      service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "5"
      service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: "{{logs_s3_bucket}}"
      service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: "web/alb_logs"
      service.beta.kubernetes.io/aws-load-balancer-connection-draining-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-connection-draining-timeout: "60"
      service.beta.kubernetes.io/aws-load-balancer-extra-security-groups: "{{web_sgs}}"
spec:
  selector:
    app: web
    env: {{env}}
  ports:
    - protocol: TCP
      port: 443
      targetPort: 8080
  type: LoadBalancer
