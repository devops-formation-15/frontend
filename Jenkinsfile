pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    alpha.eksctl.io/nodegroup-name: jenkins-node
  containers:
  - name: jenkins-agent
    image: nourzakhama2003/jenkins-agent:latest
    command: [cat]
    tty: true
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
    - name: DOCKER_API_VERSION
      value: "1.43"
  - name: dind
    image: docker:24.0.9-dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    volumeMounts:
    - name: dind-storage
      mountPath: /var/lib/docker
  volumes:
  - name: dind-storage
    emptyDir: {}
"""
      defaultContainer 'jenkins-agent'
    }
  }

  environment {
    AWS_REGION        = 'eu-north-1'
    ECR_REGISTRY      = '083347785255.dkr.ecr.eu-north-1.amazonaws.com'
    IMAGE_NAME        = 'frontend-app'
    DOCKER_HOST       = 'tcp://localhost:2375'
    DOCKER_API_VERSION = '1.43'
    VITE_API_URL      = '' // <-- Set your backend API URL here
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Wait for Docker') {
      steps {
        sh """
          echo "Waiting for Docker daemon..."
          for i in \$(seq 1 30); do
            docker info > /dev/null 2>&1 && echo "Docker ready!" && break
            echo "Attempt \$i - retrying in 3s..."
            sleep 3
          done
        """
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build --build-arg VITE_API_URL=${VITE_API_URL} -t ${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ."
      }
    }

    stage('Push to ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-ecr-creds']]) {
          sh """
            aws ecr get-login-password --region ${AWS_REGION} | \
            docker login --username AWS --password-stdin ${ECR_REGISTRY}
            docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
          """
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-ecr-creds']]) {
          sh """
            aws eks update-kubeconfig --name demo-test --region ${AWS_REGION}
            kubectl set image deployment/frontend-deployment frontend=${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} -n prod
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline succeeded! Image: ${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
    }
    failure {
      echo "❌ Pipeline failed! Check logs above."
    }
  }
}
