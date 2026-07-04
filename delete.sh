#!/bin/bash
export PROJECT_ID="my-second-project-499702"
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
export GITHUB_ORG="devopswithcloud"
export GITHUB_REPO="terraform-actions-repo"
export POOL_ID="github-actions-pool"
export PROVIDER_ID="github-actions-provider"
export SA_NAME="terraform-pipeline-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export BUCKET_NAME="${PROJECT_ID}-terraform-infra"

# Remove workload identity binding on the service account
gcloud iam service-accounts remove-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"
echo "Removed workload identity binding from ${SA_EMAIL}"

# Delete the workload identity provider
gcloud iam workload-identity-pools providers delete "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --quiet
echo "Deleted workload identity provider ${PROVIDER_ID}"

# Delete the workload identity pool
gcloud iam workload-identity-pools delete "$POOL_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --quiet
echo "Deleted workload identity pool ${POOL_ID}"

# Remove bucket IAM policy binding for the service account
gcloud storage buckets remove-iam-policy-binding "gs://${BUCKET_NAME}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"
echo "Removed roles/storage.admin binding from gs://${BUCKET_NAME}"

# Remove project-level IAM bindings for the service account
for ROLE in roles/compute.networkAdmin roles/compute.instanceAdmin.v1 roles/cloudsql.admin; do
  gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$ROLE"
  echo "Removed ${ROLE} binding from ${SA_EMAIL}"
done

# Delete the service account
gcloud iam service-accounts delete "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --quiet
echo "Deleted service account ${SA_EMAIL}"

# Delete the storage bucket (and its contents)
gcloud storage rm --recursive "gs://${BUCKET_NAME}" --quiet
echo "Deleted bucket gs://${BUCKET_NAME}"
