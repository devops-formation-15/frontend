pipeline {
    agent any

    tools {
        nodejs 'Node20'  // Ensure this is configured in Global Tool Configuration
    }

    environment {
        VERSION_NUMBER          = "${BUILD_NUMBER}"
        SERVICE_NAME            = "frontend-app"
        IMAGE_NAME              = "nourzakhama2003/front-react"   // base name without tag
        DOCKER_COMPOSE_LOCATION = "~/projects/shop/devops-scripts/stress-test-scripts/front"
        DOCKERHUB_CREDENTIALS   = "dockerhub-credentials"
    }

    stages {
        stage('Install Dependencies & Unit Tests') {
            steps {
                // Clean install dependencies (recommended for CI)
                sh 'npm ci'

                // Run unit tests (Jest, Vitest, etc.)
                sh 'npm run test'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', env.DOCKERHUB_CREDENTIALS) {
                        // Build with host network to avoid npm ECONNRESET
                        def image = docker.build("${IMAGE_NAME}", "--network=host .")

                        // Push two tags
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
                    bat """
                        sshpass -p "%VPS_PASS%" ssh -o StrictHostKeyChecking=no "%VPS_USER%@%VPS_HOST%" ^
                            "cd ${DOCKER_COMPOSE_LOCATION} || { echo 'ERROR: Directory ${DOCKER_COMPOSE_LOCATION} not found'; exit 1; } && \\
                             echo 'Deployment started' && \\
                             docker compose pull ${SERVICE_NAME} || { echo 'Pull failed'; exit 1; } && \\
                             docker compose up -d --force-recreate ${SERVICE_NAME} || { echo 'Up failed'; exit 1; } && \\
                             echo 'Deployment finished successfully' && \\
                             docker compose ps | grep ${SERVICE_NAME}"
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished'
        }
        success {
            echo '✅ Success!'
        }
        failure {
            echo '❌ Failed – check logs'
        }
    }
}