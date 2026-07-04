export PROJECT_ID="my-second-project-499702"
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
export GITHUB_ORG="devopswithcloud"
export GITHUB_REPO="terraform-actions-repo"
export POOL_ID="github-actions-pool"
export PROVIDER_ID="github-actions-provider"
export SA_NAME="terraform-pipeline-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export BUCKET_NAME="${PROJECT_ID}-terraform-infra"
export BUCKET_REGION="us-central1"

gcloud services enable iamcredentials.googleapis.com sts.googleapis.com \
  compute.googleapis.com sqladmin.googleapis.com storage.googleapis.com \
  --project="$PROJECT_ID"

gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="$PROJECT_ID" \
  --location="$BUCKET_REGION" \
  --uniform-bucket-level-access

gcloud storage buckets update "gs://${BUCKET_NAME}" --versioning

gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="Terraform Pipeline (GitHub Actions)"

for ROLE in roles/compute.networkAdmin roles/compute.instanceAdmin.v1 roles/cloudsql.admin; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$ROLE"
done

gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

gcloud iam workload-identity-pools create "$POOL_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'"

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

gcloud iam service-accounts get-iam-policy "$SA_EMAIL" --project="$PROJECT_ID" --format=json

echo "GCP_SERVICE_ACCOUNT = ${SA_EMAIL}"

echo "GCP_WORKLOAD_IDENTITY_PROVIDER = $(gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --format='value(name)')"




