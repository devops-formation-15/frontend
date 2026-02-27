pipeline {
    agent any
    tools {
        nodejs 'Node20'
    }
    environment {
        VERSION_NUMBER          = "${BUILD_NUMBER}"
        SERVICE_NAME            = "frontend-app"
        IMAGE_NAME              = "nourzakhama2003/front-react"
        DOCKER_COMPOSE_LOCATION = "~/projects/shop/devops-scripts/stress-test-scripts/front"
        DOCKERHUB_CREDENTIALS   = "dockerhub-credentials"
    }
    stages {
        stage('Install Dependencies & Unit Tests') {
            steps {
                sh 'echo "No tests configured yet"'
            }
        }
        stage('Build & Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', env.DOCKERHUB_CREDENTIALS) {
                        def image = docker.build(
                            "${IMAGE_NAME}",
                            "--build-arg VITE_API_URL=http://192.168.100.116 ."
                        )
                        image.push('latest')
                        image.push("v${VERSION_NUMBER}")
                    }
                }
            }
        }
        stage('Deploy to VPS') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'vps-vagrant-password',
                        usernameVariable: 'VPS_USER',
                        passwordVariable: 'VPS_PASS'
                    ),
                    string(credentialsId: 'VPS_HOST', variable: 'VPS_HOST')
                ]) {
                   sh '''
    sshpass -p "$VPS_PASS" ssh \
        -o StrictHostKeyChecking=no \
        "$VPS_USER@$VPS_HOST" \
        "cd ~/projects/shop/devops-scripts/stress-test-scripts/front \
         && docker compose pull frontend-app \
         && docker compose up -d --force-recreate --remove-orphans frontend-app \
         && echo 'Deployment finished successfully.' \
         && docker compose ps"
'''
                }
            }
        }
    }
    post {
        always { echo 'Pipeline finished' }
        success { echo 'Success!' }
        failure { echo 'Failed - check logs' }
    }
}