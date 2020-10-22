---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
    env: {{env}}
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  replicas: 3
  selector:
    matchLabels:
      app: api
      env: {{env}}
  template:
    metadata:
      labels:
        app: api
        env: {{env}}
    spec:
      containers:
      - name: api
        image: {{api_image}}
        imagePullPolicy: Always
        env:
        - name: PORT
          value: "3000"
        - name: DB
          value: "toptal_db"
        - name: DBHOST
          value: "{{db_host}}"
        - name: DBPORT
          value: "5432"
        envFrom:
        - secretRef:
            name: db-creds
        ports:
        - containerPort: 3000

---
apiVersion: v1
kind: Service
metadata:
    name: api-service
    labels:
        app: api
        env: {{env}}
spec:
    selector:
      app: api
      env: {{env}}
    ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
    type: ClusterIP
