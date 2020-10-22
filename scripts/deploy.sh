
#!/bin/bash
set -e

CLUSTER_NAME="$1"
WEB_ECR_REPO="$2"
API_ECR_REPO="$3"
LOGS_S3_BUCKET="$4"
WEB_SGS="$5"
API_SGS="$6"
DB_HOST="$7"
DBUSER="$9"
DBPASS="${10}"

ACCOUNT_ID=`echo $WEB_ECR_REPO | cut -d'.' -f1`
AWS_REGION=`echo $WEB_ECR_REPO | cut -d'.' -f4`
WEB_ECR_REPO_NAME=`echo $WEB_ECR_REPO | cut -d'/' -f2`
API_ECR_REPO_NAME=`echo $API_ECR_REPO | cut -d'/' -f2`
ENVIRONMENT=`echo $WEB_ECR_REPO_NAME | cut -d'-' -f2`

web_image_present=`aws ecr describe-images --registry-id ${ACCOUNT_ID} --repository-name "${WEB_ECR_REPO_NAME}" --region=${AWS_REGION} --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' | tr -d '"'`
echo $web_image_present
if [[ "$web_image_present" != 'latest' ]]; then
    web_image_present=`aws ecr describe-images --registry-id ${ACCOUNT_ID} --repository-name "${WEB_ECR_REPO_NAME}" --region=${AWS_REGION} --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[1]' | tr -d '"'`
    echo $web_image_present
    if [[ "$web_image_present" != 'latest' ]]; then
        echo "# ERROR: No 'web' related image found in requested repository with tag 'latest'"
        exit 1
    else
        WEB_IMAGE="${WEB_ECR_REPO}:latest"
    fi
else
    WEB_IMAGE="${WEB_ECR_REPO}:latest"
fi

api_image_present=`aws ecr describe-images --registry-id ${ACCOUNT_ID} --repository-name "${API_ECR_REPO_NAME}" --region=${AWS_REGION} --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' | tr -d '"'`
echo $api_image_present
if [[ "$api_image_present" != 'latest' ]]; then
    api_image_present=`aws ecr describe-images --registry-id ${ACCOUNT_ID} --repository-name "${API_ECR_REPO_NAME}" --region=${AWS_REGION} --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[1]' | tr -d '"'`
    echo $api_image_present
    if [[ "$api_image_present" != 'latest' ]]; then
        echo "# ERROR: No 'api' related image found in requested repository with tag 'latest'"
        exit 1
    else
        API_IMAGE="${API_ECR_REPO}:latest"
    fi
else
    API_IMAGE="${API_ECR_REPO}:latest"
fi

ACM_CERT_ARN=`aws acm import-certificate --certificate fileb://toptal-${ENVIRONMENT}.tmetodie.com.crt \
      --certificate-chain fileb://toptal-${ENVIRONMENT}.tmetodie.com-chain.crt \
      --private-key fileb://toptal-${ENVIRONMENT}.tmetodie.com.key --region "${AWS_REGION}" \
      | jq -r .CertificateArn`
echo $ACM_CERT_ARN
if [[ ! $ACM_CERT_ARN =~ arn* ]]; then
    echo "# ERROR: Failed to import custom certificate."
    exit 1
fi

aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"

# WEB deployment
sed "s|{{env}}|${ENVIRONMENT}|g" ../kubernetes/web-deployment.tpl > ../kubernetes/web-deployment.yml
sed -i "s|{{web_image}}|${WEB_IMAGE}|g" ../kubernetes/web-deployment.yml
sed -i "s|{{acm_cert_arn}}|${ACM_CERT_ARN}|g" ../kubernetes/web-deployment.yml
sed -i "s|{{web_sgs}}|${WEB_SGS}|g" ../kubernetes/web-deployment.yml
sed -i "s|{{logs_s3_bucket}}|${LOGS_S3_BUCKET}|g" ../kubernetes/web-deployment.yml

kubectl apply -f ../kubernetes/web-deployment.yml
echo "" > ../kubernetes/web-deployment.yml

# DB Credentials secret
base64dbuser=`echo -n "${DBUSER}" | base64`
base64dbpass=`echo -n "${DBPASS}" | base64`
sed -i "s|{{DBUSER}}|${base64dbuser}|g" ../kubernetes/db-creds-secret.yml
sed -i "s|{{DBPASS}}|${base64dbpass}|g" ../kubernetes/db-creds-secret.yml
kubectl apply -f ../kubernetes/db-creds-secret.yml
sed -i "s|${base64dbuser}|{{DBUSER}}|g" ../kubernetes/db-creds-secret.yml
sed -i "s|${base64dbpass}|{{DBPASS}}|g" ../kubernetes/db-creds-secret.yml

# API deployment
sed "s|{{env}}|${ENVIRONMENT}|g" ../kubernetes/api-deployment.tpl > ../kubernetes/api-deployment.yml
sed -i "s|{{api_image}}|${API_IMAGE}|g" ../kubernetes/api-deployment.yml
sed -i "s|{{api_sgs}}|${API_SGS}|g" ../kubernetes/api-deployment.yml
sed -i "s|{{db_host}}|${DB_HOST}|g" ../kubernetes/api-deployment.yml
sed -i "s|{{logs_s3_bucket}}|${LOGS_S3_BUCKET}|g" ../kubernetes/api-deployment.yml

kubectl apply -f ../kubernetes/api-deployment.yml
echo "" > ../kubernetes/api-deployment.yml

# ELK Logging and monitoring
kubectl apply -f ../kubernetes/elasticsearch.yml
kubectl apply -f ../kubernetes/kibana.yml
kubectl apply -f ../kubernetes/logstash-cm.yml
kubectl apply -f ../kubernetes/logstash.yml
kubectl apply -f ../kubernetes/filebeat-cm.yml
kubectl apply -f ../kubernetes/filebeat-authorization.yml
kubectl apply -f ../kubernetes/filebeat.yml
