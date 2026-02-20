pipeline {
    agent any

    tools {
        nodejs 'Node20'  // Make sure this matches the name configured in Global Tool Configuration
    }

    environment {
        VERSION_NUMBER          = "${BUILD_NUMBER}"
        SERVICE_NAME            = "frontend-app"
        IMAGE_NAME              = "nourzakhama2003/front-react:latest"   // ← your Docker Hub repo
        DOCKER_COMPOSE_LOCATION = "~/projects/shop/devops-scripts/stress-test-scripts/front"                   // path on your VPS
        DOCKERHUB_CREDENTIALS   = "dockerhub-credentials"             // ← we'll create this
    }

    stages {
        stage('Install Dependencies & Unit Tests') {
            steps {
                sh 'echo "test ..."'
               
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    // This handles both login + push cleanly (no plain-text password in logs)
                    docker.withRegistry('https://index.docker.io/v1/', env.DOCKERHUB_CREDENTIALS) {
                        def image = docker.build("${IMAGE_NAME}")
                        
                        // Push two tags: latest + versioned
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
                credentialsId: 'vps-vagrant-password',  // ← your new credential ID
                usernameVariable: 'VPS_USER',
                passwordVariable: 'VPS_PASS'
            ),
            string(credentialsId: 'VPS_HOST', variable: 'VPS_HOST')
        ]) {
            bat """
                sshpass -p "%VPS_PASS%" ssh -o StrictHostKeyChecking=no "%VPS_USER%@%VPS_HOST%" ^
                    "cd ${DOCKER_COMPOSE_LOCATION} || { echo 'ERROR: Directory not found'; exit 1; } && \\
                     echo 'Logged in as:' && whoami && \\
                     pwd && \\
                     ls -la && \\
                     docker compose pull ${SERVICE_NAME} || { echo 'Pull failed'; exit 1; } && \\
                     docker compose up -d --force-recreate ${SERVICE_NAME} || { echo 'Up failed'; exit 1; } && \\
                     echo 'Deployment finished successfully.'"
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
            echo '❌ Failed –  logs'
        }
    }
}
// test