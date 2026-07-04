pipeline {
    agent {
        label 'terraform-slave'
    }
    parameters {
        choice (
            name: 'ENVIRONMENT', 
            choices: ['dev', 'test', 'stage', 'prod'],
            description: 'Choose the environment to deploy.'
        )
        choice(
            name: 'ACTION',
            choices: 'validate\ninit\nplan\napply\ndestroy'
        )
    }

    environment {
        GCS_BUCKET = "rugged-abacus-464109-r6-iac-bucket"
        GOOGLE_APPLICATION_CREDENTIALS = "${WORKSPACE}/sa-key.json"
        TFVARS_FILE = "${params.ENVIRONMENT}.tfvars"
    }
    stages {
        stage ('Setup GCE Auth') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'SA_KEY')]) {
                    // some block
                    sh '''
                        cp $SA_KEY $GOOGLE_APPLICATION_CREDENTIALS
                    '''
                }
            }
        }

        // Initialize terraform
        stage('init') {
            steps {
                echo "Initialising the terraform"
                sh """
                terraform init --backend-config="bucket=${env.GCS_BUCKET}" --backend-config="prefix=${params.ENVIRONMENT}"
                """
            }
        }

        // Plan 
        stage ('plan') {
            when {
                expression {
                    params.ACTION == 'plan'
                }
            }
            steps {
                echo "Executing the plan for terraform"
                sh "terraform plan -var-file=${env.TFVARS_FILE}"
            }
        }

        // Apply 
        stage ('apply'){
            when {
                expression {
                    params.ACTION == 'apply'
                }
            }
            steps {
                timeout (time: 300, unit: 'SECONDS'){
                    input message: "Do you want to Apply the changes ??? ", ok: "Yes", submitter: "sivasre,i27academy"
                }
                echo "Applying terraform infra"
                sh "terraform apply -var-file=${env.TFVARS_FILE} --auto-approve"
            }
        }

        // Destroy 
        stage ('destroy') {
            when {
                expression {
                    params.ACTION == 'destroy'
                }
            }
            steps {
                timeout (time: 300, unit: 'SECONDS'){
                    input message: "Do you want to Apply the changes ??? ", ok: "Yes", submitter: "sivasre,i27academy"
                }
                echo "Destroying the terraform infra"
                sh "terraform destroy -var-file=${env.TFVARS_FILE} --auto-approve"
            }
        }
    }
    post {
        always {
            echo "******************* Do clean the workspace ******************"
            cleanWs()
        }
    }
}