pipeline {
  agent any

  parameters {
    choice(name: 'ENV', choices: ['dev', 'prod'], description: 'Select environment')
    string(name: 'COMMIT_ID', defaultValue: '', description: 'Optional Git commit SHA (leave empty for latest)')
  }

  environment {
    TF_DIR = "terraform/envs/${params.ENV}"
    TF_IN_AUTOMATION = "true"
    TF_INPUT = "false"
    AWS_REGION = "us-east-1"   // change if needed
  }

  options {
    disableConcurrentBuilds()
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          if (params.COMMIT_ID?.trim()) {
            sh """
              set -e
              git fetch --all
              git checkout ${params.COMMIT_ID}
            """
          }
          sh 'git rev-parse HEAD'
        }
      }
    }

    stage('Terraform Format') {
      steps {
        sh '''
          set -e
          cd ${TF_DIR}
          terraform fmt -recursive
        '''
      }
    }

    stage('Terraform Init + Validate') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "aws-${params.ENV}",
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            set -e
            export AWS_DEFAULT_REGION=${AWS_REGION}
            export AWS_REGION=${AWS_REGION}

            cd ${TF_DIR}
            terraform init -input=false -reconfigure -no-color
            terraform validate -no-color
          '''
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "aws-${params.ENV}",
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            set -e
            export AWS_DEFAULT_REGION=${AWS_REGION}
            export AWS_REGION=${AWS_REGION}

            cd ${TF_DIR}
            terraform plan -no-color -out=tfplan
            terraform show -no-color tfplan | tee plan.txt
          '''
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
          input message: "Apply changes for ENV=${params.ENV}?"
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "aws-${params.ENV}",
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            set -e
            export AWS_DEFAULT_REGION=${AWS_REGION}
            export AWS_REGION=${AWS_REGION}

            cd ${TF_DIR}
            terraform apply -no-color -auto-approve tfplan
          '''
        }
      }
    }
  }

  post {
    always {
      withCredentials([usernamePassword(
        credentialsId: "aws-${params.ENV}",
        usernameVariable: 'AWS_ACCESS_KEY_ID',
        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
      )]) {
        sh '''
          set +e
          export AWS_DEFAULT_REGION=${AWS_REGION}
          export AWS_REGION=${AWS_REGION}

          cd ${TF_DIR}
          terraform init -input=false -reconfigure -no-color >/dev/null 2>&1 || true
          echo "==== Terraform state list ===="
          terraform state list -no-color || true
          echo "=============================="
        '''
      }
    }
  }
}
