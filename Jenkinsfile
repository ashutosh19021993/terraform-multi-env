pipeline {
  agent any

  parameters {
    choice(
      name: 'ENV',
      choices: ['dev', 'prod'],
      description: 'Select environment to deploy'
    )
  }

  environment {
    TF_DIR    = "terraform/envs/${params.ENV}"
    TF_IN_AUTOMATION = "true"
    TF_INPUT = "false"
  }

  options {
    disableConcurrentBuilds()
    timestamps()
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Format') {
      steps {
        sh """
          set -e
          cd ${TF_DIR}
          terraform fmt -check -recursive
        """
      }
    }

    stage('Terraform Init + Validate') {
      steps {
        withCredentials([[
          \$class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: "aws-${params.ENV}"
        ]]) {
          sh """
            set -e
            cd ${TF_DIR}
            terraform init -input=false -reconfigure
            terraform validate
          """
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([[
          \$class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: "aws-${params.ENV}"
        ]]) {
          sh """
            set -e
            cd ${TF_DIR}
            terraform plan -out=tfplan
            terraform show -no-color tfplan | tee plan.txt
          """
        }
      }
      post {
        success {
          archiveArtifacts artifacts: "${TF_DIR}/tfplan", fingerprint: true
          archiveArtifacts artifacts: "${TF_DIR}/plan.txt", allowEmptyArchive: false
        }
      }
    }

    stage('Approve Apply') {
      steps {
        timeout(time: 30, unit: 'MINUTES') {
          input message: "Apply Terraform changes for ENV=${params.ENV}?"
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([[
          \$class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: "aws-${params.ENV}"
        ]]) {
          sh """
            set -e
            cd ${TF_DIR}
            terraform apply -auto-approve tfplan
          """
        }
      }
    }
  }

  post {
    always {
      sh """
        set +e
        cd ${TF_DIR}
        terraform state list || true
      """
    }
  }
}
