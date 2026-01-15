pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: tf-agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: terraform
    image: hashicorp/terraform:1.8.5
    command: ["sh", "-c", "cat"]
    tty: true
    env:
    - name: TF_IN_AUTOMATION
      value: "true"
    - name: TF_INPUT
      value: "false"
    - name: TF_PLUGIN_CACHE_DIR
      value: "/tmp/terraform-plugin-cache"
    - name: TMPDIR
      value: "/tmp"
    - name: AWS_ACCESS_KEY_ID
      value: "test"
    - name: AWS_SECRET_ACCESS_KEY
      value: "test"
    - name: AWS_DEFAULT_REGION
      value: "us-east-1"
    - name: AWS_REGION
      value: "us-east-1"
    - name: LOCALSTACK_ENDPOINT
      value: "http://host.docker.internal:4566"
    resources:
      requests:
        cpu: "250m"
        memory: "512Mi"
      limits:
        cpu: "1"
        memory: "1Gi"

  - name: aws
    image: amazon/aws-cli:2.17.0
    command: ["sh", "-c", "cat"]
    tty: true
    env:
    - name: AWS_ACCESS_KEY_ID
      value: "test"
    - name: AWS_SECRET_ACCESS_KEY
      value: "test"
    - name: AWS_DEFAULT_REGION
      value: "us-east-1"
    - name: AWS_REGION
      value: "us-east-1"
    - name: LOCALSTACK_ENDPOINT
      value: "http://host.docker.internal:4566"
"""
    }
  }

  triggers { pollSCM('H/2 * * * *') }

  parameters {
    choice(name: 'ENV', choices: ['dev', 'stage', 'prod'], description: 'Select env folder under envs/')
  }

  environment {
    TF_DIR = "terraform/envs/${params.ENV}"
    PLAN_FILE = "tfplan"
    PLAN_TXT  = "plan.txt"
  }

  options { disableConcurrentBuilds() }

  stages {
    stage("Checkout") {
      steps { checkout scm }
    }

    stage("Bootstrap LocalStack S3 backend bucket") {
      steps {
        container('aws') {
          sh '''
            set -e
            echo "Creating tf-state bucket in LocalStack (if not exists)..."
            aws --endpoint-url=${LOCALSTACK_ENDPOINT} s3api create-bucket --bucket tf-state >/dev/null 2>&1 || true
            echo "Verifying buckets:"
            aws --endpoint-url=${LOCALSTACK_ENDPOINT} s3api list-buckets
          '''
        }
      }
    }

    stage("Fmt") {
      steps {
        container('terraform') {
          sh '''
            set -e
            cd ${TF_DIR}
            terraform fmt -check -recursive
          '''
        }
      }
    }

    stage("Init + Validate") {
      steps {
        container('terraform') {
          sh '''
            set -e
            cd ${TF_DIR}

            # Clean any cached backend/provider to avoid stale endpoints or corrupted plugins
            rm -rf .terraform
            mkdir -p /tmp/terraform-plugin-cache

            terraform init -input=false -reconfigure
            terraform validate
          '''
        }
      }
    }

    stage("Plan (save + show on terminal)") {
      steps {
        container('terraform') {
          sh '''
            set -e
            cd ${TF_DIR}

            echo "Running terraform plan and saving to ${PLAN_FILE}..."
            terraform plan -out=${PLAN_FILE}

            echo ""
            echo "========== TERRAFORM PLAN (human readable) =========="
            terraform show -no-color ${PLAN_FILE} | tee ${PLAN_TXT}
            echo "====================================================="
          '''
        }
      }
      post {
        success {
          archiveArtifacts artifacts: "${TF_DIR}/${PLAN_FILE}", fingerprint: true
          archiveArtifacts artifacts: "${TF_DIR}/${PLAN_TXT}", allowEmptyArchive: false
        }
      }
    }

    stage("Approve Apply?") {
      steps {
        timeout(time: 30, unit: 'MINUTES') {
          input message: "Apply the above plan for ENV=${params.ENV}?"
        }
      }
    }

    stage("Apply (using saved plan)") {
      steps {
        container('terraform') {
          sh '''
            set -e
            cd ${TF_DIR}

            rm -rf .terraform
            mkdir -p /tmp/terraform-plugin-cache

            terraform init -input=false -reconfigure

            echo "Applying saved plan..."
            terraform apply -auto-approve ${PLAN_FILE}
          '''
        }
      }
    }
  }

  post {
    always {
      container('terraform') {
        sh '''
          set +e
          cd ${TF_DIR}
          echo ""
          echo "==== Terraform state list (if available) ===="
          terraform state list 2>/dev/null || true
          echo "============================================"
        '''
      }
    }
  }
}
