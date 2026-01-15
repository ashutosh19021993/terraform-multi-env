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
    - name: TF_DATA_DIR
      value: "/tmp/tfdata"
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
    choice(name: 'ENV', choices: ['dev', 'stage', 'prod'], description: 'Select env folder under terraform/envs/')
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

            # Run terraform from /tmp to avoid noexec workspace volumes (provider cannot start otherwise)
            rm -rf /tmp/tfwork
            mkdir -p /tmp/tfwork
            cp -R ${TF_DIR}/. /tmp/tfwork/
            cd /tmp/tfwork

            rm -rf .terraform
            mkdir -p /tmp/tfdata /tmp/terraform-plugin-cache
            export TF_DATA_DIR=/tmp/tfdata
            export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
            export TMPDIR=/tmp

            terraform init -input=false -reconfigure -no-color
            terraform validate -no-color
          '''
        }
      }
    }

    stage("Plan (save + show on terminal)") {
      steps {
        container('terraform') {
          sh '''
            set -e

            rm -rf /tmp/tfwork
            mkdir -p /tmp/tfwork
            cp -R ${TF_DIR}/. /tmp/tfwork/
            cd /tmp/tfwork

            rm -rf .terraform
            mkdir -p /tmp/tfdata /tmp/terraform-plugin-cache
            export TF_DATA_DIR=/tmp/tfdata
            export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
            export TMPDIR=/tmp

            terraform init -input=false -reconfigure -no-color

            echo "Running terraform plan and saving to ${PLAN_FILE}..."
            terraform plan -no-color -out=${PLAN_FILE}

            echo ""
            echo "========== TERRAFORM PLAN (human readable) =========="
            terraform show -no-color ${PLAN_FILE} | tee ${PLAN_TXT}
            echo "====================================================="

            # Copy artifacts back to workspace so Jenkins can archive them
            mkdir -p ${WORKSPACE}/${TF_DIR}
            cp ${PLAN_FILE} ${WORKSPACE}/${TF_DIR}/${PLAN_FILE}
            cp ${PLAN_TXT}  ${WORKSPACE}/${TF_DIR}/${PLAN_TXT}
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

            rm -rf /tmp/tfwork
            mkdir -p /tmp/tfwork
            cp -R ${TF_DIR}/. /tmp/tfwork/
            cd /tmp/tfwork

            rm -rf .terraform
            mkdir -p /tmp/tfdata /tmp/terraform-plugin-cache
            export TF_DATA_DIR=/tmp/tfdata
            export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
            export TMPDIR=/tmp

            terraform init -input=false -reconfigure -no-color

            # Bring saved plan from workspace into /tmp run dir
            cp ${WORKSPACE}/${TF_DIR}/${PLAN_FILE} ./${PLAN_FILE}

            echo "Applying saved plan..."
            terraform apply -no-color -auto-approve ${PLAN_FILE}
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

          rm -rf /tmp/tfwork
          mkdir -p /tmp/tfwork
          cp -R ${TF_DIR}/. /tmp/tfwork/
          cd /tmp/tfwork

          rm -rf .terraform
          mkdir -p /tmp/tfdata /tmp/terraform-plugin-cache
          export TF_DATA_DIR=/tmp/tfdata
          export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
          export TMPDIR=/tmp

          terraform init -input=false -reconfigure -no-color >/dev/null 2>&1 || true
          echo ""
          echo "==== Terraform state list (if available) ===="
          terraform state list -no-color 2>/dev/null || true
          echo "============================================"
        '''
      }
    }
  }
}
